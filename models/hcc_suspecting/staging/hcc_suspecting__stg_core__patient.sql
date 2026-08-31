{{ config(
     enabled = (var('claims_enabled', False) | as_bool)
            or (var('clinical_enabled', False) | as_bool)
   )
}}
select
      person_id
    , data_source
    , sex
    , birth_date
    , death_date
from {{ ref('core__patient') }}
