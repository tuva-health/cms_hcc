select
      cast({{ the_tuva_project.concat_custom(["ID", "'-'", "ICD10"]) }} as varchar) as claim_id
    , cast(ID as varchar) as person_id
    , cast('medicare' as varchar) as payer
    , cast('2025-12-15' as date) as recorded_date
    , cast('billing' as varchar) as condition_type
    , cast('icd-10-cm' as varchar) as code_system
    , cast(ICD10 as varchar) as normalized_code
    , cast('official-cms-2026-v28' as varchar) as data_source
from {{ ref('official_cms_2026_v28_diagnoses') }}
