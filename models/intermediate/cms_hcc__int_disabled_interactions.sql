{{ config(enabled = var('cms_hcc_enabled',var('tuva_packages_enabled',True)) ) -}}

with staged_eligibility as (

    select
          patient_id
        , enrollment_status
        , institutional_status
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

, interaction_factors as (

    select
          model_version
        , enrollment_status
        , institutional_status
        , short_name
        , description
        , hcc_code
        , coefficient
    from {{ ref('cms_hcc__disabled_interaction_factors') }}

)

, eligibility_with_hccs as (

    select
          staged_eligibility.patient_id
        , staged_eligibility.enrollment_status
        , staged_eligibility.institutional_status
        , staged_eligibility.model_version
        , staged_eligibility.payment_year
        , hcc_hierarchy.hcc_code
    from staged_eligibility
         inner join hcc_hierarchy
         on staged_eligibility.patient_id = hcc_hierarchy.patient_id

)

, interactions as (

    select
          eligibility_with_hccs.patient_id
        , interaction_factors.description as interaction_description
        , cast(interaction_factors.coefficient as numeric(38,3)) as coefficient
        , eligibility_with_hccs.model_version
        , eligibility_with_hccs.payment_year
        , getdate() as date_calculated
    from eligibility_with_hccs
         inner join interaction_factors
         on eligibility_with_hccs.enrollment_status = interaction_factors.enrollment_status
         and eligibility_with_hccs.institutional_status = interaction_factors.institutional_status
         and eligibility_with_hccs.hcc_code = interaction_factors.hcc_code

)

select * from interactions