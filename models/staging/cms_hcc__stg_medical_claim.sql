select
      claim_id
    , claim_line_number
    , claim_type
    , patient_id
    , claim_start_date
    , claim_end_date
    , bill_type_code
    , hcpcs_code
from {{ var('medical_claim') }}