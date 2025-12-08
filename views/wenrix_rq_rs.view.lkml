view: wenrix_rq_rs {

  # Derived Table with CTEs for JSON extraction
  # base_cte computes ID once and includes request/response JSON for other CTEs to extract from
  derived_table: {
    sql: 
      WITH base_cte AS (
        SELECT 
          toString(created_at) || '_' || toString(cityHash64(request)) || '_' || toString(cityHash64(response)) AS id,
          operation,
          result,
          created_at,
          request,
          response
        FROM ota_reports.wenrix_rq_rs
      ),
      request_cte AS (
        SELECT 
          id,
          JSONExtractString(request, 'branch') AS request_branch,
          JSONExtractString(request, 'source') AS request_source,
          JSONExtractString(request, 'booking_reference') AS request_booking_reference,
          if(JSONHas(request, 'labels'), JSONExtractString(JSONExtractRaw(request, 'labels'), 'internal_id'), NULL) AS request_internal_id
        FROM base_cte
      ),
      response_meta_cte AS (
        SELECT 
          id,
          if(JSONHas(response, 'meta'), JSONExtractString(JSONExtractRaw(response, 'meta'), 'request_id'), NULL) AS response_request_id,
          if(JSONHas(response, 'meta'), toInt32OrZero(JSONExtractString(JSONExtractRaw(response, 'meta'), 'status')), 0) AS response_status,
          if(JSONHas(response, 'meta'), JSONExtractString(JSONExtractRaw(response, 'meta'), 'timestamp'), NULL) AS response_timestamp_raw
        FROM base_cte
      ),
      response_data_cte AS (
        SELECT 
          id,
          if(JSONHas(response, 'data'), JSONExtractString(JSONExtractRaw(response, 'data'), 'booking_reference'), NULL) AS response_booking_reference,
          if(JSONHas(response, 'data'), JSONExtractString(JSONExtractRaw(response, 'data'), 'quote_id'), NULL) AS response_quote_id,
          if(JSONHas(response, 'data') AND JSONHas(JSONExtractRaw(response, 'data'), 'refund_amount'), toFloat64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'data'), 'refund_amount'), 'amount')), 0.0) AS response_refund_amount,
          if(JSONHas(response, 'data') AND JSONHas(JSONExtractRaw(response, 'data'), 'refund_amount'), JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'data'), 'refund_amount'), 'currency'), NULL) AS response_refund_currency,
          if(JSONHas(response, 'data') AND JSONHas(JSONExtractRaw(response, 'data'), 'total_penalty'), toFloat64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'data'), 'total_penalty'), 'amount')), 0.0) AS response_total_penalty,
          if(JSONHas(response, 'data') AND JSONHas(JSONExtractRaw(response, 'data'), 'total_penalty'), JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'data'), 'total_penalty'), 'currency'), NULL) AS response_total_penalty_currency,
          if(JSONHas(response, 'data'), JSONExtractString(JSONExtractRaw(response, 'data'), 'expires_at'), NULL) AS response_expires_at_raw,
          if(JSONHas(response, 'data') AND JSONHas(JSONExtractRaw(response, 'data'), 'labels'), JSONExtractString(JSONExtractRaw(JSONExtractRaw(response, 'data'), 'labels'), 'internal_id'), NULL) AS response_internal_id
        FROM base_cte
      ),
      errors_cte AS (
        SELECT 
          id,
          if(JSONHas(response, 'errors'), JSONExtractString(JSONExtractArrayRaw(response, 'errors')[1], 'code'), NULL) AS error_code,
          if(JSONHas(response, 'errors'), JSONExtractString(JSONExtractArrayRaw(response, 'errors')[1], 'message'), NULL) AS error_message,
          if(JSONHas(response, 'errors'), JSONExtractString(JSONExtractArrayRaw(response, 'errors')[1], 'type'), NULL) AS error_type,
          if(JSONHas(response, 'errors'), JSONExtractString(JSONExtractArrayRaw(response, 'errors')[1], 'title'), NULL) AS error_title
        FROM base_cte
      )
      SELECT 
        b.id,
        b.operation,
        b.result,
        b.created_at,
        r.request_branch,
        r.request_source,
        r.request_booking_reference,
        r.request_internal_id,
        rm.response_request_id,
        rm.response_status,
        if(rm.response_timestamp_raw IS NULL OR rm.response_timestamp_raw = '' OR trim(rm.response_timestamp_raw) = '', NULL, parseDateTimeBestEffortOrZero(rm.response_timestamp_raw)) AS response_timestamp,
        rd.response_booking_reference,
        rd.response_quote_id,
        rd.response_refund_amount,
        rd.response_refund_currency,
        rd.response_total_penalty,
        rd.response_total_penalty_currency,
        if(rd.response_expires_at_raw IS NULL OR rd.response_expires_at_raw = '' OR trim(rd.response_expires_at_raw) = '', NULL, parseDateTimeBestEffortOrZero(rd.response_expires_at_raw)) AS response_expires_at,
        rd.response_internal_id,
        e.error_code,
        e.error_message,
        e.error_type,
        e.error_title
      FROM base_cte b
      LEFT JOIN request_cte r ON b.id = r.id
      LEFT JOIN response_meta_cte rm ON b.id = rm.id
      LEFT JOIN response_data_cte rd ON b.id = rd.id
      LEFT JOIN errors_cte e ON b.id = e.id
    ;;
    
    sql_primary_key: id ;;
  }

  dimension: id {
    type: string
    sql: ${TABLE}.id ;;
    primary_key: yes
    hidden: yes
  }

  # -------------------------
  # 1. Basic dimensions from table columns
  # -------------------------

  dimension: operation {
    type: string
    sql: ${TABLE}.operation ;;
    group_label: "1. Basic Dimensions"
    label: "Operation"
    description: "The operation type performed (e.g., cancellation quote request)"
  }

  dimension: result {
    type: string
    sql: ${TABLE}.result ;;
    group_label: "1. Basic Dimensions"
    label: "Result"
    description: "The result of the operation (e.g., success, error)"
  }

  dimension: is_success {
    type: yesno
    sql: ${result} = 'success' ;;
    group_label: "1. Basic Dimensions"
    label: "Is Success"
    description: "Whether the operation was successful"
  }

  dimension: is_error {
    type: yesno
    sql: ${result} = 'error' ;;
    group_label: "1. Basic Dimensions"
    label: "Is Error"
    description: "Whether the operation resulted in an error"
  }

  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
    group_label: "1. Basic Dimensions"
    label: "Created"
    description: "Group of time-based dimensions for created_at"
  }

  # -------------------------
  # 2. Request JSON dimensions
  # -------------------------

  dimension: request_branch {
    type: string
    sql: ${TABLE}.request_branch ;;
    group_label: "2. Request Dimensions"
    label: "Branch"
    description: "Branch code from the request"
  }

  dimension: request_source {
    type: string
    sql: ${TABLE}.request_source ;;
    group_label: "2. Request Dimensions"
    label: "Source"
    description: "Source system from the request (e.g., amadeus)"
  }

  dimension: request_booking_reference {
    type: string
    sql: ${TABLE}.request_booking_reference ;;
    group_label: "2. Request Dimensions"
    label: "Booking Reference"
    description: "Booking reference from the request"
  }

  dimension: request_internal_id {
    type: string
    sql: ${TABLE}.request_internal_id ;;
    group_label: "2. Request Dimensions"
    label: "Internal ID"
    description: "Internal booking ID from request labels"
  }

  # -------------------------
  # 3. Response JSON dimensions - Meta fields
  # -------------------------

  dimension: response_request_id {
    type: string
    sql: ${TABLE}.response_request_id ;;
    group_label: "3. Response Meta Dimensions"
    label: "Request ID"
    description: "Request ID from response meta"
  }

  dimension: response_status {
    type: number
    sql: ${TABLE}.response_status ;;
    group_label: "3. Response Meta Dimensions"
    label: "Status"
    description: "HTTP status code from response meta"
  }

  dimension_group: response_timestamp {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.response_timestamp ;;
    group_label: "3. Response Meta Dimensions"
    label: "Timestamp"
    description: "Timestamp from response meta"
  }

  # -------------------------
  # 4. Response JSON dimensions - Success response fields
  # -------------------------

  dimension: response_booking_reference {
    type: string
    sql: ${TABLE}.response_booking_reference ;;
    group_label: "4. Response Success Dimensions"
    label: "Booking Reference"
    description: "Booking reference from successful response"
  }

  dimension: response_quote_id {
    type: string
    sql: ${TABLE}.response_quote_id ;;
    group_label: "4. Response Success Dimensions"
    label: "Quote ID"
    description: "Quote ID from successful response"
  }

  dimension: response_refund_amount {
    type: number
    sql: ${TABLE}.response_refund_amount ;;
    group_label: "4. Response Success Dimensions"
    label: "Refund Amount"
    description: "Refund amount from successful response"
  }

  dimension: response_refund_currency {
    type: string
    sql: ${TABLE}.response_refund_currency ;;
    group_label: "4. Response Success Dimensions"
    label: "Refund Currency"
    description: "Refund currency from successful response"
  }

  dimension: response_total_penalty {
    type: number
    sql: ${TABLE}.response_total_penalty ;;
    group_label: "4. Response Success Dimensions"
    label: "Total Penalty"
    description: "Total penalty amount from successful response"
  }

  dimension: response_total_penalty_currency {
    type: string
    sql: ${TABLE}.response_total_penalty_currency ;;
    group_label: "4. Response Success Dimensions"
    label: "Penalty Currency"
    description: "Total penalty currency from successful response"
  }

  dimension_group: response_expires_at {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.response_expires_at ;;
    group_label: "4. Response Success Dimensions"
    label: "Expires At"
    description: "Expiration date/time of the quote from successful response"
  }

  dimension: response_internal_id {
    type: string
    sql: ${TABLE}.response_internal_id ;;
    group_label: "4. Response Success Dimensions"
    label: "Internal ID"
    description: "Internal booking ID from response labels"
  }

  # -------------------------
  # 5. Response JSON dimensions - Error fields
  # Note: Error extraction from arrays is simplified to extract first error
  # -------------------------

  dimension: error_code {
    type: string
    sql: ${TABLE}.error_code ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Code"
    description: "Error code from error response (first error)"
  }

  dimension: error_message {
    type: string
    sql: ${TABLE}.error_message ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Message"
    description: "Error message from error response (first error)"
  }

  dimension: error_type {
    type: string
    sql: ${TABLE}.error_type ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Type"
    description: "Error type from error response (first error)"
  }

  dimension: error_title {
    type: string
    sql: ${TABLE}.error_title ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Title"
    description: "Error title from error response (first error)"
  }

  # -------------------------
  # 6. Measures
  # -------------------------

  measure: count {
    type: count
    group_label: "6. Measures"
    label: "Count"
    description: "Total count of request/response records"
  }

  measure: count_success {
    type: count
    filters: [is_success: "yes"]
    group_label: "6. Measures"
    label: "Count Success"
    description: "Count of successful operations"
  }

  measure: count_error {
    type: count
    filters: [is_error: "yes"]
    group_label: "6. Measures"
    label: "Count Error"
    description: "Count of error operations"
  }

  measure: success_rate {
    type: number
    sql: ${count_success} / NULLIF(${count}, 0) * 100.0 ;;
    value_format_name: decimal_2
    group_label: "6. Measures"
    label: "Success Rate"
    description: "Percentage of successful operations"
  }

  measure: total_refund_amount {
    type: sum
    sql: ${response_refund_amount} ;;
    value_format_name: decimal_2
    group_label: "6. Measures"
    label: "Total Refund Amount"
    description: "Total refund amount across all successful responses"
  }

  measure: total_penalty_amount {
    type: sum
    sql: ${response_total_penalty} ;;
    value_format_name: decimal_2
    group_label: "6. Measures"
    label: "Total Penalty Amount"
    description: "Total penalty amount across all successful responses"
  }

  measure: average_refund_amount {
    type: average
    sql: ${response_refund_amount} ;;
    value_format_name: decimal_2
    group_label: "6. Measures"
    label: "Average Refund Amount"
    description: "Average refund amount per successful operation"
  }

  measure: average_penalty_amount {
    type: average
    sql: ${response_total_penalty} ;;
    value_format_name: decimal_2
    group_label: "6. Measures"
    label: "Average Penalty Amount"
    description: "Average penalty amount per successful operation"
  }

  measure: distinct_booking_references {
    type: count_distinct
    sql: ${request_booking_reference} ;;
    group_label: "6. Measures"
    label: "Distinct Booking References"
    description: "Distinct count of booking references in requests"
  }

  measure: distinct_quote_ids {
    type: count_distinct
    sql: ${response_quote_id} ;;
    group_label: "6. Measures"
    label: "Distinct Quote IDs"
    description: "Distinct count of quote IDs in responses"
  }

  measure: distinct_operations {
    type: count_distinct
    sql: ${operation} ;;
    group_label: "6. Measures"
    label: "Distinct Operations"
    description: "Distinct count of operation types"
  }

}
