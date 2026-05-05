connection: "ota_phoenix"

include: "/views/**/*.view.lkml"


explore: wenrix_rq_rs {
  label: "Wenrix Cancelation"
  description: "Analytics for Wenrix API request and response data"

  join: validating_carrier {
    type: left_outer
    relationship: many_to_one
    sql_on: ${wenrix_rq_rs.request_internal_id} = ${validating_carrier.booking_id} ;;
  }
}