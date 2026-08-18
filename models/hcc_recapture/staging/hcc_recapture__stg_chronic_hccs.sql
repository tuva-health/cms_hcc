{{ config(
     enabled = var('claims_enabled', False) | as_bool
   )
}}

{% if var('hcc_recapture_chronic_hccs', false) | as_bool %}

select
    cast(hcc_code as {{dbt.type_string()}}) as hcc_code
    , cast(model_version as {{dbt.type_string()}}) as model_version
    , cast(chronic_flag as {{dbt.type_int()}}) as chronic_flag
from {{ ref('chronic_hccs') }}

{% else %}

select
    cast(hcc_code as {{ dbt.type_string() }}) as hcc_code
    , cast(model_version as {{ dbt.type_string() }}) as model_version
    , cast(chronic_flag as {{ dbt.type_int() }}) as chronic_flag
from {{ ref('hcc_recapture__chronic_hccs') }}

{% endif %}
