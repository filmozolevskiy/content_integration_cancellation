view: wenrix_rq_rs {

  # Primary key for the view
  sql_table_name: ota_reports.wenrix_rq_rs ;;

  dimension: id {
    type: string
    sql: toString(created_at) || '_' || toString(hash(request)) || '_' || toString(hash(response)) ;;
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
    sql: JSONExtractString(${TABLE}.request, 'branch') ;;
    group_label: "2. Request Dimensions"
    label: "Branch"
    description: "Branch code from the request"
  }

  dimension: request_source {
    type: string
    sql: JSONExtractString(${TABLE}.request, 'source') ;;
    group_label: "2. Request Dimensions"
    label: "Source"
    description: "Source system from the request (e.g., amadeus)"
  }

  dimension: request_booking_reference {
    type: string
    sql: JSONExtractString(${TABLE}.request, 'booking_reference') ;;
    group_label: "2. Request Dimensions"
    label: "Booking Reference"
    description: "Booking reference from the request"
  }

  dimension: request_internal_id {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.request, 'labels'), 'internal_id') ;;
    group_label: "2. Request Dimensions"
    label: "Internal ID"
    description: "Internal booking ID from request labels"
  }

  # -------------------------
  # 3. Response JSON dimensions - Meta fields
  # -------------------------

  dimension: response_request_id {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.response, 'meta'), 'request_id') ;;
    group_label: "3. Response Meta Dimensions"
    label: "Request ID"
    description: "Request ID from response meta"
  }

  dimension: response_status {
    type: number
    sql: toInt32OrZero(JSONExtractString(JSONExtractRaw(${TABLE}.response, 'meta'), 'status')) ;;
    group_label: "3. Response Meta Dimensions"
    label: "Status"
    description: "HTTP status code from response meta"
  }

  dimension_group: response_timestamp {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: if(empty(nullIf(JSONExtractString(JSONExtractRaw(${TABLE}.response, 'meta'), 'timestamp'), '')), NULL, parseDateTimeBestEffort(nullIf(JSONExtractString(JSONExtractRaw(${TABLE}.response, 'meta'), 'timestamp'), ''))) ;;
    group_label: "3. Response Meta Dimensions"
    label: "Timestamp"
    description: "Timestamp from response meta"
  }

  # -------------------------
  # 4. Response JSON dimensions - Success response fields
  # -------------------------

  dimension: response_booking_reference {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.response, 'data'), 'booking_reference') ;;
    group_label: "4. Response Success Dimensions"
    label: "Booking Reference"
    description: "Booking reference from successful response"
  }

  dimension: response_quote_id {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.response, 'data'), 'quote_id') ;;
    group_label: "4. Response Success Dimensions"
    label: "Quote ID"
    description: "Quote ID from successful response"
  }

  dimension: response_refund_amount {
    type: number
    sql: toFloat64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'data'), 'refund_amount'), 'amount')) ;;
    group_label: "4. Response Success Dimensions"
    label: "Refund Amount"
    description: "Refund amount from successful response"
  }

  dimension: response_refund_currency {
    type: string
    sql: JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'data'), 'refund_amount'), 'currency') ;;
    group_label: "4. Response Success Dimensions"
    label: "Refund Currency"
    description: "Refund currency from successful response"
  }

  dimension: response_total_penalty {
    type: number
    sql: toFloat64OrZero(JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'data'), 'total_penalty'), 'amount')) ;;
    group_label: "4. Response Success Dimensions"
    label: "Total Penalty"
    description: "Total penalty amount from successful response"
  }

  dimension: response_total_penalty_currency {
    type: string
    sql: JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'data'), 'total_penalty'), 'currency') ;;
    group_label: "4. Response Success Dimensions"
    label: "Penalty Currency"
    description: "Total penalty currency from successful response"
  }

  dimension_group: response_expires_at {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: if(empty(nullIf(JSONExtractString(JSONExtractRaw(${TABLE}.response, 'data'), 'expires_at'), '')), NULL, parseDateTimeBestEffort(nullIf(JSONExtractString(JSONExtractRaw(${TABLE}.response, 'data'), 'expires_at'), ''))) ;;
    group_label: "4. Response Success Dimensions"
    label: "Expires At"
    description: "Expiration date/time of the quote from successful response"
  }

  dimension: response_internal_id {
    type: string
    sql: JSONExtractString(JSONExtractRaw(JSONExtractRaw(${TABLE}.response, 'data'), 'labels'), 'internal_id') ;;
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
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.response, 'errors', 0), 'code') ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Code"
    description: "Error code from error response (first error)"
  }

  dimension: error_message {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.response, 'errors', 0), 'message') ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Message"
    description: "Error message from error response (first error)"
  }

  dimension: error_type {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.response, 'errors', 0), 'type') ;;
    group_label: "5. Response Error Dimensions"
    label: "Error Type"
    description: "Error type from error response (first error)"
  }

  dimension: error_title {
    type: string
    sql: JSONExtractString(JSONExtractRaw(${TABLE}.response, 'errors', 0), 'title') ;;
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
