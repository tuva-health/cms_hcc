{{ config(enabled = var('cms_hcc_enabled',var('tuva_packages_enabled',True)) ) -}}

with adjustment_rates as (

    select
          model_version
        , payment_year
        , normalization_factor
        , ma_coding_pattern_adjustment
    from {{ ref('cms_hcc__adjustment_rates') }}

)

, demographic_factors as (

    select
          patient_id
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_demographic_factors') }}

)

, disease_factors as (

    select
          patient_id
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_disease_factors') }}

)

, enrollment_interactions as (

    select
          patient_id
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_enrollment_interactions') }}

)

, disabled_interactions as (

    select
          patient_id
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_disabled_interactions') }}

)

, disease_interactions as (

    select
          patient_id
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_disease_interactions') }}

)

, payment_hcc_counts as (

    select
          patient_id
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_payment_hcc_counts') }}

)

, unioned_factors as (

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
    select * from payment_hcc_counts

)

, raw as (

    select
          patient_id
        , cast(sum(coefficient) as numeric(38,3)) as risk_score
        , model_version
        , payment_year
        , getdate() as date_calculated
    from unioned_factors
    group by
          patient_id
        , model_version
        , payment_year

)

, normalized as (

    select
          raw.patient_id
        , raw.risk_score as raw_risk_score
        , cast(raw.risk_score / adjustment_rates.normalization_factor as numeric(38,3)) as normalized_risk_score
        , raw.model_version
        , raw.payment_year
        , raw.date_calculated
    from raw
         left join adjustment_rates
         on raw.payment_year = adjustment_rates.payment_year
         and raw.model_version = adjustment_rates.model_version

)

, payment as (

    select
          normalized.patient_id
        , normalized.raw_risk_score
        , normalized.normalized_risk_score
        , cast(normalized.normalized_risk_score * (1 - adjustment_rates.ma_coding_pattern_adjustment) as numeric(38,3)) as payment_risk_score
        , normalized.model_version
        , normalized.payment_year
        , normalized.date_calculated
    from normalized
         left join adjustment_rates
         on normalized.payment_year = adjustment_rates.payment_year
         and normalized.model_version = adjustment_rates.model_version

)

select
      patient_id
    , raw_risk_score
    , normalized_risk_score
    , payment_risk_score
    , model_version
    , payment_year
    , date_calculated
from payment