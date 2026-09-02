select
      cast(ID as varchar) as person_id
    , case cast(SEX as integer) when 1 then 'male' when 2 then 'female' end as sex
    , cast(strptime(DOB, '%m/%d/%Y') as date) as birth_date
    , cast(null as date) as death_date
    , cast('official-cms-2026-v28' as varchar) as data_source
from {{ ref('official_cms_2026_v28_beneficiaries') }}
