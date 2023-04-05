{{ config(enabled = var('cms_hcc_enabled',var('tuva_packages_enabled',True)) ) -}}

/*
    Staging HCCs that will be used in disease factor calculations.
    Final output includes:
        - hccs without a hierarchy
        - lower-level hccs with hierarchy where top-level hcc is missing
        - top-level hccs from hierarchy
*/
with hcc_mapping as (

    select distinct
          patient_id
        , hcc_code
    from {{ ref('cms_hcc__int_hcc_mapping') }}

),

hcc_hierarchy as (

    select * from {{ ref('cms_hcc__disease_hierarchy') }}

),

/*
    selecting hccs that do not have a hierarchy
    all codes in this cte are included in final output
*/
hccs_without_hierarchy as (

    select distinct
          hcc_mapping.patient_id
        , hcc_mapping.hcc_code
    from hcc_mapping
         left join hcc_hierarchy as hcc_top_level
         on hcc_mapping.hcc_code = hcc_top_level.hcc_code
         left join hcc_hierarchy as hcc_exclusions
         on hcc_mapping.hcc_code = hcc_exclusions.hccs_to_exclude
    where hcc_top_level.hcc_code is null
    and hcc_exclusions.hccs_to_exclude is null

),

/*
    selecting hccs that have a hierarchy to be evaluated
*/
hccs_with_hierarchy as (

    select
          hcc_mapping.patient_id
        , hcc_mapping.hcc_code
        , hcc_hierarchy.hcc_code as top_level_hcc
    from hcc_mapping
         inner join hcc_hierarchy
        on hcc_mapping.hcc_code = hccs_to_exclude

),

/*
    applying hcc hierarchy and grouping by patient and hcc
    to account for multiple hcc combinations
*/
hierarchy_applied as (

    select
          hccs_with_hierarchy.patient_id
        , hccs_with_hierarchy.hcc_code
        , max(hcc_mapping.hcc_code) as top_level_hcc
    from hccs_with_hierarchy
         left join hcc_mapping
            on hcc_mapping.patient_id = hccs_with_hierarchy.patient_id
            and hcc_mapping.hcc_code = hccs_with_hierarchy.top_level_hcc
    group by
          hccs_with_hierarchy.patient_id
        , hccs_with_hierarchy.hcc_code

),

/*
    selecting lower-level hccs in hierarchy where a top-level hcc is not present
    all codes in this cte are included in final output
*/
lower_level_hccs_to_include as (

    select distinct
          patient_id
        , hcc_code
    from hierarchy_applied
    where top_level_hcc is null

),

/*
    selecting top-level hccs
    all codes in this cte are included in final output
*/
top_level_hccs as (

    select distinct
          hcc_mapping.patient_id
        , hcc_mapping.hcc_code
    from hcc_mapping
         inner join hcc_hierarchy
        on hcc_mapping.hcc_code = hcc_hierarchy.hcc_code

),

unioned as (

    select * from hccs_without_hierarchy
    union
    select * from lower_level_hccs_to_include
    union
    select * from top_level_hccs

)

select * from unioned