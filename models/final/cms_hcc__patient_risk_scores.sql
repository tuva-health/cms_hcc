with seed_adjustment_rates as (

    select
          model_version
        , payment_year
        , normalization_factor
        , ma_coding_pattern_adjustment
    from {{ ref('cms_hcc__adjustment_rates') }}

)

, risk_factors as (

    select
          patient_id
        , coefficient
        , model_version
        , payment_year
    from {{ ref('cms_hcc__patient_risk_factors') }}

)

, raw as (

    select
          patient_id
        , cast(sum(coefficient) as numeric(38,3)) as risk_score
        , model_version
        , payment_year
    from risk_factors
    group by
          patient_id
        , model_version
        , payment_year

)

, normalized as (

    select
          raw.patient_id
        , raw.risk_score as raw_risk_score
        , cast(raw.risk_score / seed_adjustment_rates.normalization_factor as numeric(38,3)) as normalized_risk_score
        , raw.model_version
        , raw.payment_year
    from raw
         left join seed_adjustment_rates
         on raw.payment_year = seed_adjustment_rates.payment_year
         and raw.model_version = seed_adjustment_rates.model_version

)

, payment as (

    select
          normalized.patient_id
        , normalized.raw_risk_score
        , normalized.normalized_risk_score
        , cast(normalized.normalized_risk_score * (1 - seed_adjustment_rates.ma_coding_pattern_adjustment) as numeric(38,3)) as payment_risk_score
        , normalized.model_version
        , normalized.payment_year
    from normalized
         left join seed_adjustment_rates
         on normalized.payment_year = seed_adjustment_rates.payment_year
         and normalized.model_version = seed_adjustment_rates.model_version

)

select
      patient_id
    , raw_risk_score
    , normalized_risk_score
    , payment_risk_score
    , model_version
    , payment_year
    , getdate() as date_calculated
from payment