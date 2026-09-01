{{ config(tags=['official_cms_hcc_validation']) }}

with expected_adjustments as (
    select 'CMS-HCC-V24' as model_version, 2018 as payment_year, 1.015 as normalization_factor, 0.059 as coding_adjustment, 1.00 as blend_weight
    union all select 'CMS-HCC-V24', 2019, 1.038, 0.059, 1.00
    union all select 'CMS-HCC-V24', 2020, 1.069, 0.059, 1.00
    union all select 'CMS-HCC-V24', 2021, 1.097, 0.059, 1.00
    union all select 'CMS-HCC-V24', 2022, 1.118, 0.059, 1.00
    union all select 'CMS-HCC-V24', 2023, 1.127, 0.059, 1.00
    union all select 'CMS-HCC-V24', 2024, 1.146, 0.059, 0.67
    union all select 'CMS-HCC-V28', 2024, 1.015, 0.059, 0.33
    union all select 'CMS-HCC-V24', 2025, 1.153, 0.059, 0.33
    union all select 'CMS-HCC-V28', 2025, 1.045, 0.059, 0.67
    union all select 'CMS-HCC-V28', 2026, 1.067, 0.059, 1.00
    union all select 'CMS-HCC-V28', 2027, 1.079, 0.059, 1.00
)

, actual_adjustments as (
    select
          model_version
        , payment_year
        , normalization_factor
        , ma_coding_pattern_adjustment as coding_adjustment
        , blend_weight
    from {{ ref('cms_hcc__adjustment_rates') }}
)

, adjustment_failures as (
    select
          'unexpected_or_changed_adjustment' as failure_type
        , actual.model_version
        , actual.payment_year
    from actual_adjustments as actual
    left join expected_adjustments as expected
        on actual.model_version = expected.model_version
        and actual.payment_year = expected.payment_year
    where expected.model_version is null
       or abs(actual.normalization_factor - expected.normalization_factor) > 0.000001
       or abs(actual.coding_adjustment - expected.coding_adjustment) > 0.000001
       or abs(actual.blend_weight - expected.blend_weight) > 0.000001

    union all

    select
          'missing_adjustment' as failure_type
        , expected.model_version
        , expected.payment_year
    from expected_adjustments as expected
    left join actual_adjustments as actual
        on expected.model_version = actual.model_version
        and expected.payment_year = actual.payment_year
    where actual.model_version is null
)

, institutional_failures as (
    select 'demographic_institutional_status' as failure_type, model_version, cast(null as integer) as payment_year
    from {{ ref('cms_hcc__demographic_factors') }}
    where institutional_status = 'Yes' and enrollment_status <> 'Institutional'

    union all
    select 'disabled_interaction_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__disabled_interaction_factors') }}
    where institutional_status = 'Yes' and enrollment_status <> 'Institutional'

    union all
    select 'disease_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__disease_factors') }}
    where institutional_status = 'Yes' and enrollment_status <> 'Institutional'

    union all
    select 'disease_interaction_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__disease_interaction_factors') }}
    where institutional_status = 'Yes' and enrollment_status <> 'Institutional'

    union all
    select 'enrollment_interaction_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__enrollment_interaction_factors') }}
    where institutional_status = 'Yes' and enrollment_status <> 'Institutional'

    union all
    select 'hcc_count_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__payment_hcc_count_factors') }}
    where institutional_status = 'Yes' and enrollment_status <> 'Institutional'
)

, new_enrollee_failures as (
    select
          'under_65_disabled_new_enrollee_zero_coefficient' as failure_type
        , model_version
        , cast(null as integer) as payment_year
    from {{ ref('cms_hcc__demographic_factors') }}
    where enrollment_status = 'New'
      and orec = 'Disabled'
      and age_group in ('0-34', '35-44', '45-54', '55-59', '60-64')
      and coalesce(coefficient, 0) = 0
)

select * from adjustment_failures
union all
select * from institutional_failures
union all
select * from new_enrollee_failures
