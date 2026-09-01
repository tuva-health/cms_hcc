select
      cast(ID as varchar) as person_id
    , cast('medicare' as varchar) as payer
    , case ID when 'P_CE' then cast('2024-01-01' as date) else cast('2025-07-01' as date) end as enrollment_start_date
    , cast('2025-12-31' as date) as enrollment_end_date
    , cast(cast(OREC as integer) as varchar) as original_reason_entitlement_code
    , cast(null as varchar) as dual_status_code
    , cast(null as varchar) as medicare_status_code
    , case ID when 'P_CE' then 'Continuing' else 'New' end as enrollment_status
    , cast(0 as integer) as long_term_institutional_flag
    , cast(0 as integer) as institutional_snp_flag
    , cast('medicare' as varchar) as payer_type
    , cast('official-cms-2026-v28' as varchar) as data_source
from {{ ref('official_cms_2026_v28_beneficiaries') }}
