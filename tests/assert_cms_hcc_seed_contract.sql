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
       or actual.model_version is null
       or actual.payment_year is null
       or actual.normalization_factor is null
       or actual.coding_adjustment is null
       or actual.blend_weight is null
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

, adjustment_duplicate_failures as (
    select
          'duplicate_adjustment' as failure_type
        , model_version
        , payment_year
    from actual_adjustments
    group by
          model_version
        , payment_year
    having count(*) <> 1
)

, adjustment_cardinality_failures as (
    select
          'adjustment_cardinality_not_12' as failure_type
        , cast(null as {{ dbt.type_string() }}) as model_version
        , cast(null as integer) as payment_year
    from (
        select count(*) as row_count
        from actual_adjustments
    ) as adjustment_count
    where row_count <> 12
)

, expected_factor_inventory as (
    select 'demographic_factor_inventory' as failure_type, 848 as row_count, 48 as institutional_row_count
    union all select 'disabled_interaction_factor_inventory', 40, 40
    union all select 'disease_factor_inventory', 1369, 178
    union all select 'disease_interaction_factor_inventory', 961, 103
    union all select 'enrollment_interaction_factor_inventory', 14, 2
    union all select 'payment_hcc_count_factor_inventory', 73, 1
)

, actual_factor_inventory as (
    select
          'demographic_factor_inventory' as failure_type
        , count(*) as row_count
        , sum(case when institutional_status = 'Yes' then 1 else 0 end) as institutional_row_count
    from {{ ref('cms_hcc__demographic_factors') }}

    union all
    select
          'disabled_interaction_factor_inventory'
        , count(*)
        , sum(case when institutional_status = 'Yes' then 1 else 0 end)
    from {{ ref('cms_hcc__disabled_interaction_factors') }}

    union all
    select
          'disease_factor_inventory'
        , count(*)
        , sum(case when institutional_status = 'Yes' then 1 else 0 end)
    from {{ ref('cms_hcc__disease_factors') }}

    union all
    select
          'disease_interaction_factor_inventory'
        , count(*)
        , sum(case when institutional_status = 'Yes' then 1 else 0 end)
    from {{ ref('cms_hcc__disease_interaction_factors') }}

    union all
    select
          'enrollment_interaction_factor_inventory'
        , count(*)
        , sum(case when institutional_status = 'Yes' then 1 else 0 end)
    from {{ ref('cms_hcc__enrollment_interaction_factors') }}

    union all
    select
          'payment_hcc_count_factor_inventory'
        , count(*)
        , sum(case when institutional_status = 'Yes' then 1 else 0 end)
    from {{ ref('cms_hcc__payment_hcc_count_factors') }}
)

, factor_inventory_failures as (
    select
          expected.failure_type
        , cast(null as {{ dbt.type_string() }}) as model_version
        , cast(null as integer) as payment_year
    from expected_factor_inventory as expected
    inner join actual_factor_inventory as actual
        on expected.failure_type = actual.failure_type
    where expected.row_count <> actual.row_count
       or expected.institutional_row_count <> actual.institutional_row_count
)

, institutional_failures as (
    select 'demographic_institutional_status' as failure_type, model_version, cast(null as integer) as payment_year
    from {{ ref('cms_hcc__demographic_factors') }}
    where institutional_status = 'Yes'
      and (enrollment_status is null or enrollment_status <> 'Institutional')

    union all
    select 'disabled_interaction_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__disabled_interaction_factors') }}
    where institutional_status = 'Yes'
      and (enrollment_status is null or enrollment_status <> 'Institutional')

    union all
    select 'disease_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__disease_factors') }}
    where institutional_status = 'Yes'
      and (enrollment_status is null or enrollment_status <> 'Institutional')

    union all
    select 'disease_interaction_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__disease_interaction_factors') }}
    where institutional_status = 'Yes'
      and (enrollment_status is null or enrollment_status <> 'Institutional')

    union all
    select 'enrollment_interaction_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__enrollment_interaction_factors') }}
    where institutional_status = 'Yes'
      and (enrollment_status is null or enrollment_status <> 'Institutional')

    union all
    select 'hcc_count_institutional_status', model_version, cast(null as integer)
    from {{ ref('cms_hcc__payment_hcc_count_factors') }}
    where institutional_status = 'Yes'
      and (enrollment_status is null or enrollment_status <> 'Institutional')
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
select * from adjustment_duplicate_failures
union all
select * from adjustment_cardinality_failures
union all
select * from factor_inventory_failures
union all
select * from institutional_failures
union all
select * from new_enrollee_failures
