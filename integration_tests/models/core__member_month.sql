select
      cast(ID as varchar) as person_id
    , cast('medicare' as varchar) as payer
    , cast('202512' as varchar) as year_month
    , cast('official-cms-2026-v28' as varchar) as data_source
from {{ ref('official_cms_2026_v28_beneficiaries') }}
