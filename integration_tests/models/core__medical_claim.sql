select
      cast({{ the_tuva_project.concat_custom(["ID", "'-'", "ICD10"]) }} as varchar) as claim_id
    , cast('1' as varchar) as claim_line_number
    , cast('institutional' as varchar) as claim_type
    , cast(ID as varchar) as person_id
    , cast('medicare' as varchar) as payer
    , cast('2025-12-15' as date) as claim_start_date
    , cast('2025-12-15' as date) as claim_end_date
    , cast('111' as varchar) as bill_type_code
    , cast(null as varchar) as hcpcs_code
    , cast(null as varchar) as rendering_npi
    , cast('official-cms-2026-v28' as varchar) as data_source
from {{ ref('official_cms_2026_v28_diagnoses') }}
