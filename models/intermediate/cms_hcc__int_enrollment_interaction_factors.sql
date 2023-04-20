/*
The hcc_model_version var has been set here so it gets compiled.
*/

{% set model_version_compiled = var('cms_hcc_model_version') -%}

with demographics as (

    select
          patient_id
        , enrollment_status
        , gender
        , age_group
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , enrollment_status_default
        , medicaid_dual_status_default
        , institutional_status_default
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_demographic_factors') }}

)

, seed_interaction_factors as (

    select
          model_version
        , gender
        , enrollment_status
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , description
        , coefficient
    from {{ ref('cms_hcc__enrollment_interaction_factors') }}
    where model_version = '{{ model_version_compiled }}'

)

/*
    enrollment interaction factors for non-institutional patients use gender
*/
, non_institutional_interactions as (

    select
          demographics.patient_id
        , demographics.model_version
        , demographics.payment_year
        , seed_interaction_factors.description
        , seed_interaction_factors.coefficient
    from demographics
         inner join seed_interaction_factors
         on demographics.gender = seed_interaction_factors.gender
         and demographics.enrollment_status = seed_interaction_factors.enrollment_status
         and demographics.medicaid_status = seed_interaction_factors.medicaid_status
         and demographics.dual_status = seed_interaction_factors.dual_status
         and demographics.orec = seed_interaction_factors.orec
         and demographics.institutional_status = seed_interaction_factors.institutional_status
    where demographics.institutional_status = 'No'

)

/*
    enrollment interaction factors for institutional patients do not use gender
*/
, institutional_interactions as (

    select
          demographics.patient_id
        , demographics.model_version
        , demographics.payment_year
        , seed_interaction_factors.description
        , seed_interaction_factors.coefficient
    from demographics
         inner join seed_interaction_factors
         on demographics.enrollment_status = seed_interaction_factors.enrollment_status
         and demographics.medicaid_status = seed_interaction_factors.medicaid_status
         and demographics.dual_status = seed_interaction_factors.dual_status
         and demographics.orec = seed_interaction_factors.orec
         and demographics.institutional_status = seed_interaction_factors.institutional_status
    where demographics.institutional_status = 'Yes'

)

, unioned as (

    select * from non_institutional_interactions
    union all
    select * from institutional_interactions

)

select
      cast(patient_id as {{ dbt.type_string() }}) as patient_id
    , cast(description as {{ dbt.type_string() }}) as description
    , round(cast(coefficient as {{ dbt.type_numeric() }}),3) as coefficient
    , cast(model_version as {{ dbt.type_string() }}) as model_version
    , cast(payment_year as integer) as payment_year
    , cast(getdate() as {{ dbt.type_timestamp() }}) as date_calculated
from unioned