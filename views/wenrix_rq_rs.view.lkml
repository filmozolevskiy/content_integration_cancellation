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
    label: "1. Basic | Operation"
    description: "The operation type performed (e.g., cancellation quote request)"
  }

  dimension: result {
    type: string
    sql: ${TABLE}.result ;;
    label: "1. Basic | Result"
    description: "The result of the operation (e.g., success, error)"
  }

  dimension: is_success {
    type: yesno
    sql: ${result} = 'success' ;;
    label: "1. Basic | Is Success"
    description: "Whether the operation was successful"
  }

  dimension: is_error {
    type: yesno
    sql: ${result} = 'error' ;;
    label: "1. Basic | Is Error"
    description: "Whether the operation resulted in an error"
  }

  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, quarter, year, date_month_num, date_quarter_num, date_year]
    sql: ${TABLE}.created_at ;;
    label: "1. Basic | Created"
    description: "Group of time-based dimensions for created_at"
  }
  
  # -------------------------
  # 2. Request JSON dimensions
  # -------------------------
 
  dimension: request_branch {
    type: string
    sql: JSONExtractString(${TABLE}.request, 'branch') ;;
    label: "2. Request | Branch"
    description: "Branch code from the request"
  }

  dimension: request_source {
    type: string
    sql: JSONExtractString(${TABLE}.request, 'source') ;;
    label: "2. Request | Source"
    description: "Source system from the request (e.g., amadeus)"
  }

  dimension: request_booking_reference {
    type: string
    sql: JSONExtractString(${TABLE}.request, 'booking_reference') ;;
    label: "2. Request | Booking Reference"
    description: "Booking reference from the request"
  }

  dimension: request_internal_id {
    type: string
    sql: JSONExtractString(JSONExtract(${TABLE}.request, 'labels'), 'internal_id') ;;
    label: "2. Request | Internal ID"
    description: "Internal booking ID from request labels"
  }

  # -------------------------
  # 3. Response JSON dimensions - Meta fields
  # -------------------------
  
  dimension: response_request_id {
    type: string
    sql: JSONExtractString(JSONExtract(${TABLE}.response, 'meta'), 'request_id') ;;
    label: "3. Response Meta | Request ID"
    description: "Request ID from response meta"
  }

  dimension: response_status {
    type: number
    sql: toInt32OrZero(JSONExtractString(JSONExtract(${TABLE}.response, 'meta'), 'status')) ;;
    label: "3. Response Meta | Status"
    description: "HTTP status code from response meta"
  }

  dimension_group: response_timestamp {
    type: time
    timeframes: [raw, date, week, month, quarter, year, date_month_num, date_quarter_num, date_year]
    sql: parseDateTimeBestEffort(JSONExtractString(JSONExtract(${TABLE}.response, 'meta'), 'timestamp')) ;;
    label: "3. Response Meta | Timestamp"
    description: "Timestamp from response meta"
  }

  # -------------------------
  # 4. Response JSON dimensions - Success response fields
  # -------------------------
  
  dimension: response_booking_reference {
    type: string
    sql: JSONExtractString(JSONExtract(${TABLE}.response, 'data'), 'booking_reference') ;;
    label: "4. Response Success | Booking Reference"
    description: "Booking reference from successful response"
  }

  dimension: response_quote_id {
    type: string
    sql: JSONExtractString(JSONExtract(${TABLE}.response, 'data'), 'quote_id') ;;
    label: "4. Response Success | Quote ID"
    description: "Quote ID from successful response"
  }

  dimension: response_refund_amount {
    type: number
    sql: toFloat64OrZero(JSONExtractString(JSONExtract(JSONExtract(${TABLE}.response, 'data'), 'refund_amount'), 'amount')) ;;
    label: "4. Response Success | Refund Amount"
    description: "Refund amount from successful response"
  }

  dimension: response_refund_currency {
    type: string
    sql: JSONExtractString(JSONExtract(JSONExtract(${TABLE}.response, 'data'), 'refund_amount'), 'currency') ;;
    label: "4. Response Success | Refund Currency"
    description: "Refund currency from successful response"
  }

  dimension: response_total_penalty {
    type: number
    sql: toFloat64OrZero(JSONExtractString(JSONExtract(JSONExtract(${TABLE}.response, 'data'), 'total_penalty'), 'amount')) ;;
    label: "4. Response Success | Total Penalty"
    description: "Total penalty amount from successful response"
  }

  dimension: response_total_penalty_currency {
    type: string
    sql: JSONExtractString(JSONExtract(JSONExtract(${TABLE}.response, 'data'), 'total_penalty'), 'currency') ;;
    label: "4. Response Success | Penalty Currency"
    description: "Total penalty currency from successful response"
  }

  dimension_group: response_expires_at {
    type: time
    timeframes: [raw, date, week, month, quarter, year, date_month_num, date_quarter_num, date_year]
    sql: parseDateTimeBestEffort(JSONExtractString(JSONExtract(${TABLE}.response, 'data'), 'expires_at')) ;;
    label: "4. Response Success | Expires At"
    description: "Expiration date/time of the quote from successful response"
  }

  dimension: response_internal_id {
    type: string
    sql: JSONExtractString(JSONExtract(JSONExtract(${TABLE}.response, 'data'), 'labels'), 'internal_id') ;;
    label: "4. Response Success | Internal ID"
    description: "Internal booking ID from response labels"
  }

  # -------------------------
  # 5. Response JSON dimensions - Error fields
  # Note: Error extraction from arrays is simplified to extract first error
  # -------------------------

  dimension: error_code {
    type: string
    sql: JSONExtractString(JSONExtract(${TABLE}.response, 'errors', 0), 'code') ;;
    label: "5. Response Error | Error Code"
    description: "Error code from error response (first error)"
  }

  dimension: error_message {
    type: string
    sql: JSONExtractString(JSONExtract(${TABLE}.response, 'errors', 0), 'message') ;;
    label: "5. Response Error | Error Message"
    description: "Error message from error response (first error)"
  }

  dimension: error_type {
    type: string
    sql: JSONExtractString(JSONExtract(${TABLE}.response, 'errors', 0), 'type') ;;
    label: "5. Response Error | Error Type"
    description: "Error type from error response (first error)"
  }

  dimension: error_title {
    type: string
    sql: JSONExtractString(JSONExtract(${TABLE}.response, 'errors', 0), 'title') ;;
    label: "5. Response Error | Error Title"
    description: "Error title from error response (first error)"
  }

  # -------------------------
  # 6. Measures
  # -------------------------

  measure: count {
    type: count
    label: "6. Measures | Count"
    description: "Total count of request/response records"
  }

  measure: count_success {
    type: count
    filters: [is_success: "yes"]
    label: "6. Measures | Count Success"
    description: "Count of successful operations"
  }

  measure: count_error {
    type: count
    filters: [is_error: "yes"]
    label: "6. Measures | Count Error"
    description: "Count of error operations"
  }

  measure: success_rate {
    type: number
    sql: ${count_success} / NULLIF(${count}, 0) * 100.0 ;;
    value_format_name: decimal_2
    label: "6. Measures | Success Rate"
    description: "Percentage of successful operations"
  }

  measure: total_refund_amount {
    type: sum
    sql: ${response_refund_amount} ;;
    value_format_name: decimal_2
    label: "6. Measures | Total Refund Amount"
    description: "Total refund amount across all successful responses"
  }

  measure: total_penalty_amount {
    type: sum
    sql: ${response_total_penalty} ;;
    value_format_name: decimal_2
    label: "6. Measures | Total Penalty Amount"
    description: "Total penalty amount across all successful responses"
  }

  measure: average_refund_amount {
    type: average
    sql: ${response_refund_amount} ;;
    value_format_name: decimal_2
    label: "6. Measures | Average Refund Amount"
    description: "Average refund amount per successful operation"
  }

  measure: average_penalty_amount {
    type: average
    sql: ${response_total_penalty} ;;
    value_format_name: decimal_2
    label: "6. Measures | Average Penalty Amount"
    description: "Average penalty amount per successful operation"
  }

  measure: distinct_booking_references {
    type: count_distinct
    sql: ${request_booking_reference} ;;
    label: "6. Measures | Distinct Booking References"
    description: "Distinct count of booking references in requests"
  }

  measure: distinct_quote_ids {
    type: count_distinct
    sql: ${response_quote_id} ;;
    label: "6. Measures | Distinct Quote IDs"
    description: "Distinct count of quote IDs in responses"
  }

  measure: distinct_operations {
    type: count_distinct
    sql: ${operation} ;;
    label: "6. Measures | Distinct Operations"
    description: "Distinct count of operation types"
  }

}

