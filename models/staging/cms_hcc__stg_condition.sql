select
      claim_id
    , patient_id
    , code_type
    , code
from {{ var('condition') }}