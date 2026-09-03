{{ config(tags=['official_cms_hcc_validation']) }}

with expected_hccs as (
    select ID as person_id, '20' as hcc_code from {{ ref('official_cms_2026_v28_expected_scores') }} where HCC20 = 1
    union all
    select ID, '37' from {{ ref('official_cms_2026_v28_expected_scores') }} where HCC37 = 1
    union all
    select ID, '226' from {{ ref('official_cms_2026_v28_expected_scores') }} where HCC226 = 1
    union all
    select ID, '280' from {{ ref('official_cms_2026_v28_expected_scores') }} where HCC280 = 1
    union all
    select ID, '326' from {{ ref('official_cms_2026_v28_expected_scores') }} where HCC326 = 1
)

, actual_hccs as (
    select distinct person_id, hcc_code
    from {{ ref('cms_hcc__int_hcc_hierarchy') }}
    where model_version = 'CMS-HCC-V28'
      and payment_year = 2026
      and collection_end_date = cast('2025-12-31' as date)
)

, expected_interactions as (
    select ID as person_id, '37' as hcc_code_1, '226' as hcc_code_2
    from {{ ref('official_cms_2026_v28_expected_scores') }} where DIABETES_HF_V28 = 1
    union all
    select ID, '226', '280'
    from {{ ref('official_cms_2026_v28_expected_scores') }} where HF_CHR_LUNG_V28 = 1
    union all
    select ID, '226', '326'
    from {{ ref('official_cms_2026_v28_expected_scores') }} where HF_KIDNEY_V28 = 1
)

, actual_interactions as (
    select distinct person_id, hcc_code_1, hcc_code_2
    from {{ ref('cms_hcc__int_disease_interaction_factors') }}
    where model_version = 'CMS-HCC-V28'
      and payment_year = 2026
      and collection_end_date = cast('2025-12-31' as date)
)

, failures as (
    (select 'missing_hcc' as failure, * from expected_hccs except select 'missing_hcc', * from actual_hccs)
    union all
    (select 'unexpected_hcc' as failure, * from actual_hccs except select 'unexpected_hcc', * from expected_hccs)
    union all
    (select 'missing_interaction' as failure, person_id, {{ the_tuva_project.concat_custom(["hcc_code_1", "'+'", "hcc_code_2"]) }} as hcc_code from expected_interactions
     except
     select 'missing_interaction', person_id, {{ the_tuva_project.concat_custom(["hcc_code_1", "'+'", "hcc_code_2"]) }} from actual_interactions)
    union all
    (select 'unexpected_interaction' as failure, person_id, {{ the_tuva_project.concat_custom(["hcc_code_1", "'+'", "hcc_code_2"]) }} as hcc_code from actual_interactions
     except
     select 'unexpected_interaction', person_id, {{ the_tuva_project.concat_custom(["hcc_code_1", "'+'", "hcc_code_2"]) }} from expected_interactions)
)

select * from failures
