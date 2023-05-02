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
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_demographic_factors') }}

)

, hcc_hierarchy as (

    select
          patient_id
        , hcc_code
    from {{ ref('cms_hcc__int_hcc_hierarchy') }}

)

, seed_interaction_factors as (

    select
          model_version
        , enrollment_status
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , short_name
        , description
        , hcc_code_1
        , hcc_code_2
        , coefficient
    from {{ ref('cms_hcc__disease_interaction_factors') }}
    where model_version = '{{ model_version_compiled }}'

)

, demographics_with_hccs as (

    select
          demographics.patient_id
        , demographics.enrollment_status
        , demographics.medicaid_status
        , demographics.dual_status
        , demographics.orec
        , demographics.institutional_status
        , demographics.model_version
        , demographics.payment_year
        , hcc_hierarchy.hcc_code
    from demographics
         inner join hcc_hierarchy
         on demographics.patient_id = hcc_hierarchy.patient_id

)

/*
    interaction factors for institutional patients use only
    enrollment_status and institutional_status
*/
, institutional_interactions as (

    select
          demographics_with_hccs.patient_id
        , demographics_with_hccs.model_version
        , demographics_with_hccs.payment_year
        , interactions_code_1.description
        , interactions_code_1.hcc_code_1
        , interactions_code_1.hcc_code_2
        , interactions_code_1.coefficient
    from demographics_with_hccs
         inner join seed_interaction_factors as interactions_code_1
         on demographics_with_hccs.enrollment_status = interactions_code_1.enrollment_status
         and demographics_with_hccs.institutional_status = interactions_code_1.institutional_status
         and demographics_with_hccs.hcc_code = interactions_code_1.hcc_code_1
    where demographics_with_hccs.institutional_status = 'Yes'

)

, non_institutional_interactions as (

    select
          demographics_with_hccs.patient_id
        , demographics_with_hccs.model_version
        , demographics_with_hccs.payment_year
        , interactions_code_1.description
        , interactions_code_1.hcc_code_1
        , interactions_code_1.hcc_code_2
        , interactions_code_1.coefficient
    from demographics_with_hccs
         inner join seed_interaction_factors as interactions_code_1
         on demographics_with_hccs.enrollment_status = interactions_code_1.enrollment_status
         and demographics_with_hccs.medicaid_status = interactions_code_1.medicaid_status
         and demographics_with_hccs.dual_status = interactions_code_1.dual_status
         and demographics_with_hccs.orec = interactions_code_1.orec
         and demographics_with_hccs.institutional_status = interactions_code_1.institutional_status
         and demographics_with_hccs.hcc_code = interactions_code_1.hcc_code_1
    where demographics_with_hccs.institutional_status = 'No'

)

, unioned as (

    select * from institutional_interactions
    union all
    select * from non_institutional_interactions

)

, disease_interactions as (

    select
          unioned.patient_id
        , unioned.hcc_code_1
        , unioned.hcc_code_2
        , unioned.description
        , unioned.coefficient
        , unioned.model_version
        , unioned.payment_year
    from unioned
        inner join demographics_with_hccs as interactions_code_2
        on unioned.patient_id = interactions_code_2.patient_id
        and unioned.hcc_code_2 = interactions_code_2.hcc_code
)

select
      cast(patient_id as {{ dbt.type_string() }}) as patient_id
    , cast(hcc_code_1 as {{ dbt.type_string() }}) as hcc_code_1
    , cast(hcc_code_2 as {{ dbt.type_string() }}) as hcc_code_2
    , cast(description as {{ dbt.type_string() }}) as description
    , round(cast(coefficient as {{ dbt.type_numeric() }}),3) as coefficient
    , cast(model_version as {{ dbt.type_string() }}) as model_version
    , cast(payment_year as integer) as payment_year
    , cast(getdate() as {{ dbt.type_timestamp() }}) as date_calculated
from disease_interactions