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
        , demographics.enrollment_status_default
        , demographics.medicaid_dual_status_default
        , demographics.institutional_status_default
        , demographics.model_version
        , demographics.payment_year
        , hcc_hierarchy.hcc_code
    from demographics
         inner join hcc_hierarchy
         on demographics.patient_id = hcc_hierarchy.patient_id

)

, demographics_with_interactions as (

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

)

, disease_interactions as (

    select
          demographics_with_interactions.patient_id
        , demographics_with_interactions.hcc_code_1
        , demographics_with_interactions.hcc_code_2
        , demographics_with_interactions.description
        , demographics_with_interactions.coefficient
        , demographics_with_interactions.model_version
        , demographics_with_interactions.payment_year
        , getdate() as date_calculated
    from demographics_with_interactions
        inner join demographics_with_hccs as interactions_code_2
        on demographics_with_interactions.patient_id = interactions_code_2.patient_id
        and demographics_with_interactions.hcc_code_2 = interactions_code_2.hcc_code
)

select
      patient_id
    , hcc_code_1
    , hcc_code_2
    , description
    , cast(coefficient as numeric(38,3)) as coefficient
    , model_version
    , payment_year
    , getdate() as date_calculated
from disease_interactions