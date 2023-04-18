/*
The hcc_model_version var has been set here so it gets compiled.
*/

{% set model_version_compiled = var('cms_hcc_model_version') -%}

with eligibility as (

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
    from {{ ref('cms_hcc__int_prep_eligibility') }}

)

, seed_demographic_factors as (

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
    and model_version = '{{ model_version_compiled }}'

)

, new_enrollees as (

    select
          eligibility.patient_id
        , eligibility.enrollment_status
        , eligibility.gender
        , eligibility.age_group
        , eligibility.medicaid_status
        , eligibility.dual_status
        , eligibility.orec
        , eligibility.institutional_status
        , eligibility.enrollment_status_default
        , eligibility.medicaid_dual_status_default
        , eligibility.institutional_status_default
        , eligibility.model_version
        , eligibility.payment_year
        , seed_demographic_factors.coefficient
    from eligibility
         inner join seed_demographic_factors
         on eligibility.enrollment_status = seed_demographic_factors.enrollment_status
         and eligibility.gender = seed_demographic_factors.gender
         and eligibility.age_group = seed_demographic_factors.age_group
         and eligibility.medicaid_status = seed_demographic_factors.medicaid_status
         and eligibility.orec = seed_demographic_factors.orec
    where eligibility.enrollment_status = 'New'

)

, continuining_enrollees as (

    select
          eligibility.patient_id
        , eligibility.enrollment_status
        , eligibility.gender
        , eligibility.age_group
        , eligibility.medicaid_status
        , eligibility.dual_status
        , eligibility.orec
        , eligibility.institutional_status
        , eligibility.enrollment_status_default
        , eligibility.medicaid_dual_status_default
        , eligibility.institutional_status_default
        , eligibility.model_version
        , eligibility.payment_year
        , seed_demographic_factors.coefficient
    from eligibility
         inner join seed_demographic_factors
         on eligibility.enrollment_status = seed_demographic_factors.enrollment_status
         and eligibility.gender = seed_demographic_factors.gender
         and eligibility.age_group = seed_demographic_factors.age_group
         and eligibility.medicaid_status = seed_demographic_factors.medicaid_status
         and eligibility.dual_status = seed_demographic_factors.dual_status
         and eligibility.orec = seed_demographic_factors.orec
         and eligibility.institutional_status = seed_demographic_factors.institutional_status
    where eligibility.enrollment_status = 'Continuing'

)

/*
    The CMS-HCC model does not have factors for ESRD or null medicare status
    for these edge-cases, we default to 'Aged' and dual_status is Non or Partial.
*/
, other_enrollees as (

    select
          eligibility.patient_id
        , eligibility.enrollment_status
        , eligibility.gender
        , eligibility.age_group
        , eligibility.medicaid_status
        , eligibility.dual_status
        , eligibility.orec
        , eligibility.institutional_status
        , eligibility.enrollment_status_default
        , eligibility.medicaid_dual_status_default
        , eligibility.institutional_status_default
        , eligibility.model_version
        , eligibility.payment_year
        , seed_demographic_factors.coefficient
    from eligibility
         inner join seed_demographic_factors
         on eligibility.enrollment_status = seed_demographic_factors.enrollment_status
         and eligibility.gender = seed_demographic_factors.gender
         and eligibility.age_group = seed_demographic_factors.age_group
         and eligibility.medicaid_status = seed_demographic_factors.medicaid_status
    where seed_demographic_factors.orec = 'Aged'
    and (eligibility.orec = 'ESRD'
      or eligibility.orec is null)
    and (seed_demographic_factors.dual_status in ('Non', 'Partial')
      or seed_demographic_factors.dual_status is null)

)

, unioned as (

    select * from new_enrollees
    union
    select * from continuining_enrollees
    union
    select * from other_enrollees

)

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
    , cast(coefficient as numeric(38,3)) as coefficient
    , model_version
    , payment_year
    , getdate() as date_calculated
from unioned