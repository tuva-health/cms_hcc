{{ config(
     enabled = (var('claims_enabled', False) | as_bool)
            or (var('clinical_enabled', False) | as_bool)
   )
}}

select
      person_id
    , payer
    , data_source
    , model_version
    , hcc_code
    , hcc_description
    , reason
    , contributing_factor
    , suspect_date
    , tuva_last_run
from {{ ref('hcc_suspecting__list_all') }}
    {% if target.type in ['fabric', 'sqlserver'] %}
        where (current_year_billed = 0
            or current_year_billed is null)
    {% else %}
        where (current_year_billed = false
            or current_year_billed is null)
    {% endif %}
