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

, interaction_factors as (

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

)

, eligibility_with_hccs as (

    select
          staged_eligibility.patient_id
        , staged_eligibility.enrollment_status
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

, eligibility_with_interactions as (

    select
          eligibility_with_hccs.patient_id
        , eligibility_with_hccs.model_version
        , eligibility_with_hccs.payment_year
        , interactions_code_1.description
        , interactions_code_1.hcc_code_1
        , interactions_code_1.hcc_code_2
        , interactions_code_1.coefficient
    from eligibility_with_hccs
         inner join interaction_factors as interactions_code_1
         on eligibility_with_hccs.enrollment_status = interactions_code_1.enrollment_status
         and eligibility_with_hccs.medicaid_status = interactions_code_1.medicaid_status
         and eligibility_with_hccs.dual_status = interactions_code_1.dual_status
         and eligibility_with_hccs.orec = interactions_code_1.orec
         and eligibility_with_hccs.institutional_status = interactions_code_1.institutional_status
         and eligibility_with_hccs.hcc_code = interactions_code_1.hcc_code_1

)

, disease_interactions as (

    select
          eligibility_with_interactions.patient_id
        , eligibility_with_interactions.hcc_code_1
        , eligibility_with_interactions.hcc_code_2
        , eligibility_with_interactions.description as interaction_description
        , cast(eligibility_with_interactions.coefficient as numeric(38,3)) as coefficient
        , eligibility_with_interactions.model_version
        , eligibility_with_interactions.payment_year
        , getdate() as date_calculated
    from eligibility_with_interactions
        inner join eligibility_with_hccs as interactions_code_2
        on eligibility_with_interactions.patient_id = interactions_code_2.patient_id
        and eligibility_with_interactions.hcc_code_2 = interactions_code_2.hcc_code
)

select * from disease_interactions