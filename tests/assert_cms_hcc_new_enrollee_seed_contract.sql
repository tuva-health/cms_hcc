{{ config(tags=['official_cms_hcc_validation']) }}

with model_versions as (
    select 'CMS-HCC-V24' as model_version
    union all select 'CMS-HCC-V28'
)

, plan_segments as (
    select cast(null as {{ dbt.type_string() }}) as plan_segment
    union all select 'C-SNP'
)

, genders as (
    select 'Female' as gender
    union all select 'Male'
)

, age_groups as (
    select '0-34' as age_group
    union all select '35-44'
    union all select '45-54'
    union all select '55-59'
    union all select '60-64'
)

, medicaid_statuses as (
    select 'No' as medicaid_status
    union all select 'Yes'
)

, expected_disabled_rows as (
    select
          model_versions.model_version
        , cast('Demographic' as {{ dbt.type_string() }}) as factor_type
        , cast('New' as {{ dbt.type_string() }}) as enrollment_status
        , plan_segments.plan_segment
        , genders.gender
        , age_groups.age_group
        , medicaid_statuses.medicaid_status
        , cast(null as {{ dbt.type_string() }}) as dual_status
        , cast('Disabled' as {{ dbt.type_string() }}) as orec
        , cast(null as {{ dbt.type_string() }}) as institutional_status
    from model_versions
    cross join plan_segments
    cross join genders
    cross join age_groups
    cross join medicaid_statuses
)

, actual_disabled_rows as (
    select
          model_version
        , factor_type
        , enrollment_status
        , plan_segment
        , gender
        , age_group
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , coefficient
    from {{ ref('cms_hcc__demographic_factors') }}
    where enrollment_status = 'New'
      and orec = 'Disabled'
      and age_group in ('0-34', '35-44', '45-54', '55-59', '60-64')
)

, actual_aged_rows as (
    select
          model_version
        , factor_type
        , enrollment_status
        , plan_segment
        , gender
        , age_group
        , medicaid_status
        , dual_status
        , orec
        , institutional_status
        , coefficient
    from {{ ref('cms_hcc__demographic_factors') }}
    where enrollment_status = 'New'
      and orec = 'Aged'
      and age_group in ('0-34', '35-44', '45-54', '55-59', '60-64')
)

, expected_matches as (
    select
          expected.model_version
        , expected.plan_segment
        , expected.gender
        , expected.age_group
        , expected.medicaid_status
        , disabled.coefficient as disabled_coefficient
        , aged.coefficient as aged_coefficient
        , disabled.model_version as disabled_match
        , aged.model_version as aged_match
    from expected_disabled_rows as expected
    left join actual_disabled_rows as disabled
        on expected.model_version = disabled.model_version
        and expected.factor_type = disabled.factor_type
        and expected.enrollment_status = disabled.enrollment_status
        and (
            expected.plan_segment = disabled.plan_segment
            or (expected.plan_segment is null and disabled.plan_segment is null)
        )
        and expected.gender = disabled.gender
        and expected.age_group = disabled.age_group
        and expected.medicaid_status = disabled.medicaid_status
        and expected.dual_status is null
        and disabled.dual_status is null
        and expected.orec = disabled.orec
        and expected.institutional_status is null
        and disabled.institutional_status is null
    left join actual_aged_rows as aged
        on expected.model_version = aged.model_version
        and expected.factor_type = aged.factor_type
        and expected.enrollment_status = aged.enrollment_status
        and (
            expected.plan_segment = aged.plan_segment
            or (expected.plan_segment is null and aged.plan_segment is null)
        )
        and expected.gender = aged.gender
        and expected.age_group = aged.age_group
        and expected.medicaid_status = aged.medicaid_status
        and expected.dual_status is null
        and aged.dual_status is null
        and aged.orec = 'Aged'
        and expected.institutional_status is null
        and aged.institutional_status is null
)

, missing_or_changed_rows as (
    select
          case
              when disabled_match is null then 'missing_disabled_row'
              when aged_match is null then 'missing_aged_counterpart'
              when disabled_coefficient is null then 'null_disabled_coefficient'
              when aged_coefficient is null then 'null_aged_coefficient'
              when disabled_coefficient = 0 then 'zero_disabled_coefficient'
              else 'coefficient_mismatch'
          end as failure_type
        , model_version
        , plan_segment
        , gender
        , age_group
        , medicaid_status
    from expected_matches
    where disabled_match is null
       or aged_match is null
       or disabled_coefficient is null
       or aged_coefficient is null
       or disabled_coefficient = 0
       or abs(disabled_coefficient - aged_coefficient) > 0.000001
)

, unexpected_disabled_rows as (
    select
          'unexpected_disabled_row' as failure_type
        , actual.model_version
        , actual.plan_segment
        , actual.gender
        , actual.age_group
        , actual.medicaid_status
    from actual_disabled_rows as actual
    left join expected_disabled_rows as expected
        on actual.model_version = expected.model_version
        and actual.factor_type = expected.factor_type
        and actual.enrollment_status = expected.enrollment_status
        and (
            actual.plan_segment = expected.plan_segment
            or (actual.plan_segment is null and expected.plan_segment is null)
        )
        and actual.gender = expected.gender
        and actual.age_group = expected.age_group
        and actual.medicaid_status = expected.medicaid_status
        and actual.dual_status is null
        and expected.dual_status is null
        and actual.orec = expected.orec
        and actual.institutional_status is null
        and expected.institutional_status is null
    where expected.model_version is null
)

, unexpected_aged_rows as (
    select
          'unexpected_aged_counterpart' as failure_type
        , actual.model_version
        , actual.plan_segment
        , actual.gender
        , actual.age_group
        , actual.medicaid_status
    from actual_aged_rows as actual
    left join expected_disabled_rows as expected
        on actual.model_version = expected.model_version
        and actual.factor_type = expected.factor_type
        and actual.enrollment_status = expected.enrollment_status
        and (
            actual.plan_segment = expected.plan_segment
            or (actual.plan_segment is null and expected.plan_segment is null)
        )
        and actual.gender = expected.gender
        and actual.age_group = expected.age_group
        and actual.medicaid_status = expected.medicaid_status
        and actual.dual_status is null
        and expected.dual_status is null
        and actual.institutional_status is null
        and expected.institutional_status is null
    where expected.model_version is null
)

, disabled_cardinality_failure as (
    select
          'disabled_row_cardinality_not_80' as failure_type
        , cast(null as {{ dbt.type_string() }}) as model_version
        , cast(null as {{ dbt.type_string() }}) as plan_segment
        , cast(null as {{ dbt.type_string() }}) as gender
        , cast(null as {{ dbt.type_string() }}) as age_group
        , cast(null as {{ dbt.type_string() }}) as medicaid_status
    from (
        select count(*) as row_count
        from actual_disabled_rows
    ) as disabled_count
    where row_count <> 80
)

, aged_cardinality_failure as (
    select
          'aged_counterpart_cardinality_not_80' as failure_type
        , cast(null as {{ dbt.type_string() }}) as model_version
        , cast(null as {{ dbt.type_string() }}) as plan_segment
        , cast(null as {{ dbt.type_string() }}) as gender
        , cast(null as {{ dbt.type_string() }}) as age_group
        , cast(null as {{ dbt.type_string() }}) as medicaid_status
    from (
        select count(*) as row_count
        from actual_aged_rows
    ) as aged_count
    where row_count <> 80
)

select * from missing_or_changed_rows
union all
select * from unexpected_disabled_rows
union all
select * from unexpected_aged_rows
union all
select * from disabled_cardinality_failure
union all
select * from aged_cardinality_failure
