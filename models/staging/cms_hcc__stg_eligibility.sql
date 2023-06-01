select
      patient_id
    , gender
    , birth_date
    , enrollment_start_date
    , enrollment_end_date
    , dual_status_code
    , medicare_status_code
from {{ var('eligibility') }}