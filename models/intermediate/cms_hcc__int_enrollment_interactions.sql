{{ config(enabled = var('cms_hcc_enabled',var('tuva_packages_enabled',True)) ) -}}

with staged_eligibility as (

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
    from {{ ref('cms_hcc__stg_eligibility') }}

)

, interaction_factors as (

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

)

/*
    enrollment interaction factors for non-institutional patients use gender
*/
, non_institutional_patient_interactions as (

    select
          staged_eligibility.patient_id
        , interaction_factors.description as interaction_description
        , cast(interaction_factors.coefficient as numeric(38,3)) as coefficient
        , staged_eligibility.model_version
        , staged_eligibility.payment_year
        , getdate() as date_calculated
    from staged_eligibility
         inner join interaction_factors
         on staged_eligibility.gender = interaction_factors.gender
         and staged_eligibility.enrollment_status = interaction_factors.enrollment_status
         and staged_eligibility.medicaid_status = interaction_factors.medicaid_status
         and staged_eligibility.dual_status = interaction_factors.dual_status
         and staged_eligibility.orec = interaction_factors.orec
         and staged_eligibility.institutional_status = interaction_factors.institutional_status
    where staged_eligibility.institutional_status = 'No'

)

/*
    enrollment interaction factors for institutional patients do not use gender
*/
, institutional_patient_interactions as (

    select
          staged_eligibility.patient_id
        , interaction_factors.description as interaction_description
        , cast(interaction_factors.coefficient as numeric(38,3)) as coefficient
        , staged_eligibility.model_version
        , staged_eligibility.payment_year
        , getdate() as date_calculated
    from staged_eligibility
         inner join interaction_factors
         on staged_eligibility.enrollment_status = interaction_factors.enrollment_status
         and staged_eligibility.medicaid_status = interaction_factors.medicaid_status
         and staged_eligibility.dual_status = interaction_factors.dual_status
         and staged_eligibility.orec = interaction_factors.orec
         and staged_eligibility.institutional_status = interaction_factors.institutional_status
    where staged_eligibility.institutional_status = 'Yes'

)

, unioned as (

    select * from non_institutional_patient_interactions
    union all
    select * from institutional_patient_interactions

)

select * from unioned