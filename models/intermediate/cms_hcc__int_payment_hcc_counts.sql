{{ config(enabled = var('cms_hcc_enabled',var('tuva_packages_enabled',True)) ) -}}

with staged_eligibility as (

    select
          patient_id
        , enrollment_status
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , model_version
        , payment_year
    from {{ ref('cms_hcc__stg_eligibility') }}

)

, payment_hcc_count_factors as (

    select
          model_version
        , enrollment_status
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , payment_hcc_count
        , description
        , coefficient
    from {{ ref('cms_hcc__payment_hcc_count_factors') }}

)

, hcc_hierarchy as (

    select
          patient_id
        , hcc_code
    from {{ ref('cms_hcc__int_hcc_hierarchy') }}

)

, eligibility_with_hcc_counts as (

        select
          staged_eligibility.patient_id
        , staged_eligibility.enrollment_status
        , staged_eligibility.medicaid_status
        , staged_eligibility.dual_status
        , staged_eligibility.orec
        , staged_eligibility.institutional_status
        , staged_eligibility.model_version
        , staged_eligibility.payment_year
        , count(hcc_hierarchy.hcc_code) as hcc_count
    from staged_eligibility
         inner join hcc_hierarchy
         on staged_eligibility.patient_id = hcc_hierarchy.patient_id
    group by
          staged_eligibility.patient_id
        , staged_eligibility.enrollment_status
        , staged_eligibility.medicaid_status
        , staged_eligibility.dual_status
        , staged_eligibility.orec
        , staged_eligibility.institutional_status
        , staged_eligibility.model_version
        , staged_eligibility.payment_year

)

, hcc_counts_normalized as (

    select
          patient_id
        , enrollment_status
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , model_version
        , payment_year
        , case
            when hcc_count > 10 then '>=10'
            else cast(hcc_count as {{ dbt.type_string() }})
          end as hcc_count_string
    from eligibility_with_hcc_counts

)

, patient_hcc_counts as (

    select
          hcc_counts_normalized.patient_id
        , payment_hcc_count_factors.description
        , cast(payment_hcc_count_factors.coefficient as numeric(38,3)) as coefficient
        , hcc_counts_normalized.model_version
        , hcc_counts_normalized.payment_year
        , getdate() as date_calculated
    from hcc_counts_normalized
         inner join payment_hcc_count_factors
         on hcc_counts_normalized.enrollment_status = payment_hcc_count_factors.enrollment_status
         and hcc_counts_normalized.medicaid_status = payment_hcc_count_factors.medicaid_status
         and hcc_counts_normalized.dual_status = payment_hcc_count_factors.dual_status
         and hcc_counts_normalized.orec = payment_hcc_count_factors.orec
         and hcc_counts_normalized.institutional_status = payment_hcc_count_factors.institutional_status
         and hcc_counts_normalized.hcc_count_string = payment_hcc_count_factors.payment_hcc_count

)

select * from patient_hcc_counts