with demographic_factors as (

    select
          patient_id
        , concat(
              concat(enrollment_status, '-Enrollee')
            , ' / '
            , gender
            , ' / '
            , age_group
            , ' / '
            , case
                when medicaid_status = 'Yes' then 'Medicaid'
                else 'Non-Medicaid'
                end
            , ' / '
            , dual_status
            , ' / '
            , orec
            , ' / '
            , case
                when institutional_status = 'Yes' then 'Institutional'
                else 'Non-Institutional'
                end
          ) as description
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_demographic_factors') }}

)

, demographic_defaults as (

    select
          patient_id
        , enrollment_status_default
        , medicaid_dual_status_default
        , institutional_status_default
    from {{ ref('cms_hcc__int_demographic_factors') }}

)

, disease_factors as (

    select
          patient_id
        , concat(hcc_description,' (HCC ',hcc_code,')') as description
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_disease_factors') }}

)

, enrollment_interactions as (

    select
          patient_id
        , description
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_enrollment_interaction_factors') }}

)

, disabled_interactions as (

    select
          patient_id
        , description
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_disabled_interaction_factors') }}

)

, disease_interactions as (

    select
          patient_id
        , description
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_disease_interaction_factors') }}

)

, hcc_counts as (

    select
          patient_id
        , description
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_hcc_count_factors') }}

)

, unioned as (

    select * from demographic_factors
    union all
    select * from disease_factors
    union all
    select * from enrollment_interactions
    union all
    select * from disabled_interactions
    union all
    select * from disease_interactions
    union all
    select * from hcc_counts

)

, add_defaults as (

    select
          unioned.patient_id
        , demographic_defaults.enrollment_status_default
        , demographic_defaults.medicaid_dual_status_default
        , demographic_defaults.institutional_status_default
        , unioned.description as risk_factor_description
        , unioned.coefficient
        , unioned.model_version
        , unioned.payment_year
        , getdate() as date_calculated
    from unioned
         left join demographic_defaults
         on unioned.patient_id = demographic_defaults.patient_id

)

select
      patient_id
    , enrollment_status_default
    , medicaid_dual_status_default
    , institutional_status_default
    , risk_factor_description
    , coefficient
    , model_version
    , payment_year
    , date_calculated
from add_defaults