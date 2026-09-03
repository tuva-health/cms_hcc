select
      cast(ID as varchar) as person_id
    , case cast(SEX as integer) when 1 then 'male' when 2 then 'female' end as sex
{#
        DOB is m/d/Y. try_to_cast_date ignores the format on most adapters and
        would yield null here, so parse per dialect.
      #}
      {%- if target.type in ['fabric', 'sqlserver'] %}
    , cast(convert(date, DOB, 101) as date) as birth_date
      {%- elif target.type == 'athena' %}
    , cast(date_parse(DOB, '%m/%d/%Y') as date) as birth_date
      {%- elif target.type == 'bigquery' %}
    , cast(parse_date('%m/%d/%Y', DOB) as date) as birth_date
      {%- elif target.type in ['snowflake', 'redshift', 'postgres'] %}
    , cast(to_date(DOB, 'MM/DD/YYYY') as date) as birth_date
      {%- else %}
    , cast(strptime(DOB, '%m/%d/%Y') as date) as birth_date
      {%- endif %}
    , cast(null as date) as death_date
    , cast('official-cms-2026-v28' as varchar) as data_source
from {{ ref('official_cms_2026_v28_beneficiaries') }}
