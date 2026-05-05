view: validating_carrier {

  # Aggregates the latest validating carrier (airline_code) per booking_id from
  # the raw events table over the last 90 days. Joined to wenrix_rq_rs in the
  # explore via request_internal_id = booking_id.
  derived_table: {
    sql:
      SELECT
        toString(booking_id) AS booking_id,
        argMax(airline_code, date_added) AS validating_carrier
      FROM ota_phoenix_v7.raw
      WHERE day_added >= today() - 90
      GROUP BY booking_id
    ;;
  }

  dimension: booking_id {
    type: string
    sql: ${TABLE}.booking_id ;;
    primary_key: yes
    hidden: yes
  }

  dimension: validating_carrier {
    type: string
    sql: ${TABLE}.validating_carrier ;;
    view_label: "Wenrix Cancelation"
    group_label: "2. Request Dimensions"
    label: "Validating Carrier"
    description: "Validating carrier (airline_code) for the booking, looked up from ota_phoenix_v7.raw using argMax(airline_code, date_added) over the last 90 days"
  }

  measure: distinct_validating_carriers {
    type: count_distinct
    sql: ${validating_carrier} ;;
    view_label: "Wenrix Cancelation"
    group_label: "6. Measures"
    label: "Distinct Validating Carriers"
    description: "Distinct count of validating carriers across joined booking_ids"
  }
}
