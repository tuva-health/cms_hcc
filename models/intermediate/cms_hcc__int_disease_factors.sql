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

, hcc_hierarchy as (

    select
          patient_id
        , hcc_code
    from {{ ref('cms_hcc__int_hcc_hierarchy') }}

)

, disease_factors as (

    select
          model_version
        , enrollment_status
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , hcc_code
        , description
        , coefficient
    from {{ ref('cms_hcc__disease_factors') }}

)

, eligibility_with_hccs as (

    select
          staged_eligibility.patient_id
        , staged_eligibility.enrollment_status
        , staged_eligibility.gender
        , staged_eligibility.age_group
        , staged_eligibility.medicaid_status
        , staged_eligibility.dual_status
        , staged_eligibility.orec
        , staged_eligibility.institutional_status
        , staged_eligibility.enrollment_status_default
        , staged_eligibility.medicaid_dual_status_default
        , staged_eligibility.institutional_status_default
        , staged_eligibility.model_version
        , staged_eligibility.payment_year
        , hcc_hierarchy.hcc_code
    from staged_eligibility
         inner join hcc_hierarchy
         on staged_eligibility.patient_id = hcc_hierarchy.patient_id

)

, patient_disease_factors as (

    select
          eligibility_with_hccs.patient_id
        , eligibility_with_hccs.hcc_code
        , disease_factors.description as hcc_description
        , cast(disease_factors.coefficient as numeric(38,3)) as coefficient
        , eligibility_with_hccs.model_version
        , eligibility_with_hccs.payment_year
        , getdate() as date_calculated
    from eligibility_with_hccs
         inner join disease_factors
         on eligibility_with_hccs.enrollment_status = disease_factors.enrollment_status
         and eligibility_with_hccs.medicaid_status = disease_factors.medicaid_status
         and eligibility_with_hccs.dual_status = disease_factors.dual_status
         and eligibility_with_hccs.orec = disease_factors.orec
         and eligibility_with_hccs.institutional_status = disease_factors.institutional_status
         and eligibility_with_hccs.hcc_code = disease_factors.hcc_code

)

select * from patient_disease_factors