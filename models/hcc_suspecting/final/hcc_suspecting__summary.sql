{{ config(
     enabled = (var('claims_enabled', False) | as_bool)
            or (var('clinical_enabled', False) | as_bool)
   )
}}

with patients as (

    select
          person_id
        , data_source
        , sex
        , birth_date
        {% if target.type == 'fabric' %}
            , floor({{ datediff('birth_date', 'GETDATE()', 'hour') }} / 8766.0) as age
        {% else %}
            , floor({{ datediff('birth_date', 'current_date', 'hour') }} / 8766.0) as age
        {% endif %}
    from {{ ref('hcc_suspecting__stg_core__patient') }}
    where death_date is null

)

, suspecting_list as (

      select
          person_id
        , payer
        , data_source
        , count(*) as gaps
    from {{ ref('hcc_suspecting__list') }}
    group by
          person_id
        , payer
        , data_source

)

, joined as (

    select
          patients.person_id
        , suspecting_list.payer
        , suspecting_list.data_source
        , patients.sex
        , patients.birth_date
        , patients.age
        , suspecting_list.gaps
    from patients
         inner join suspecting_list
         on patients.person_id = suspecting_list.person_id
         and patients.data_source = suspecting_list.data_source

)

, add_data_types as (

    select
          cast(person_id as {{ dbt.type_string() }}) as person_id
        , cast(payer as {{ dbt.type_string() }}) as payer
        , cast(data_source as {{ dbt.type_string() }}) as data_source
        , cast(sex as {{ dbt.type_string() }}) as patient_sex
        , cast(birth_date as date) as patient_birth_date
        , cast(age as integer) as patient_age
        , cast(gaps as integer) as suspecting_gaps
    from joined

)

select
      person_id
    , payer
    , data_source
    , patient_sex
    , patient_birth_date
    , patient_age
    , suspecting_gaps
    , cast('{{ var('tuva_last_run') }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from add_data_types
