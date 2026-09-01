{{ config(tags=['official_cms_hcc_validation']) }}

with expected as (
    select
          ID as person_id
        , case ID when 'P_CE' then 'CNA' else 'E' end as risk_model_code
        , case ID when 'P_CE' then SCORE_COMMUNITY_NA else SCORE_NE end as raw_score
    from {{ ref('official_cms_2026_v28_expected_scores') }}
)

, expected_adjusted as (
    select
          person_id
        , risk_model_code
        , round(raw_score, 3) as blended_risk_score
        , round(raw_score / 1.067, 3) as normalized_risk_score
        , round(round(raw_score / 1.067, 3) * (1 - 0.059), 3) as payment_risk_score
    from expected
)

, actual as (
    select
          person_id
        , risk_model_code
        , round(blended_risk_score, 3) as blended_risk_score
        , round(normalized_risk_score, 3) as normalized_risk_score
        , round(payment_risk_score, 3) as payment_risk_score
    from {{ ref('cms_hcc__patient_risk_scores_monthly') }}
    where payment_year = 2026
      and collection_end_date = cast('2025-12-31' as date)
)

, failures as (
    (select 'missing_or_changed' as failure, * from expected_adjusted
     except
     select 'missing_or_changed', * from actual)
    union all
    (select 'unexpected' as failure, * from actual
     except
     select 'unexpected', * from expected_adjusted)
)

select * from failures
