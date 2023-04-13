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

, demographic_factors as (

    select
          model_version
        , factor_type
        , enrollment_status
        , gender
        , age_group
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , coefficient
    from {{ ref('cms_hcc__demographic_factors') }}
    where plan_segment is null /* data not available */

)

, new_enrollees as (

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
        , demographic_factors.coefficient
        , staged_eligibility.model_version
        , staged_eligibility.payment_year
        , getdate() as date_calculated
    from staged_eligibility
         inner join demographic_factors
         on staged_eligibility.enrollment_status = demographic_factors.enrollment_status
         and staged_eligibility.gender = demographic_factors.gender
         and staged_eligibility.age_group = demographic_factors.age_group
         and staged_eligibility.medicaid_status = demographic_factors.medicaid_status
         and staged_eligibility.orec = demographic_factors.orec
    where staged_eligibility.enrollment_status = 'New'

)

, continuining_enrollees as (

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
        , cast(demographic_factors.coefficient as numeric(38,3)) as coefficient
        , staged_eligibility.model_version
        , staged_eligibility.payment_year
        , getdate() as date_calculated
    from staged_eligibility
         inner join demographic_factors
         on staged_eligibility.enrollment_status = demographic_factors.enrollment_status
         and staged_eligibility.gender = demographic_factors.gender
         and staged_eligibility.age_group = demographic_factors.age_group
         and staged_eligibility.medicaid_status = demographic_factors.medicaid_status
         and staged_eligibility.dual_status = demographic_factors.dual_status
         and staged_eligibility.orec = demographic_factors.orec
         and staged_eligibility.institutional_status = demographic_factors.institutional_status
    where staged_eligibility.enrollment_status = 'Continuing'

)

/*
    The CMS-HCC model does not have factors for ESRD or null medicare status
    for these edge-cases, we default to 'Aged' and dual_status is Non or Partial.
*/
, other_enrollees as (

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
        , demographic_factors.coefficient
        , staged_eligibility.model_version
        , staged_eligibility.payment_year
        , getdate() as date_calculated
    from staged_eligibility
         inner join demographic_factors
         on staged_eligibility.enrollment_status = demographic_factors.enrollment_status
         and staged_eligibility.gender = demographic_factors.gender
         and staged_eligibility.age_group = demographic_factors.age_group
         and staged_eligibility.medicaid_status = demographic_factors.medicaid_status
    where demographic_factors.orec = 'Aged'
    and (staged_eligibility.orec = 'ESRD'
      or staged_eligibility.orec is null)
    and (demographic_factors.dual_status in ('Non', 'Partial')
      or demographic_factors.dual_status is null)

)

, unioned as (

    select * from new_enrollees
    union
    select * from continuining_enrollees
    union
    select * from other_enrollees

)

select * from unioned