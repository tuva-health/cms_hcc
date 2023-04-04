{{ config(enabled = var('cms_hcc_enabled',var('tuva_packages_enabled',True)) ) -}}

/*
Steps for staging the medical claim data:
    1) Filter to risk-adjustable claims per claim type for the collection year.
    2) Gather diagnosis codes from Condition for the eligible claims.
    3) Map and filter diagnosis codes to HCCs

Jinja is used to set payment and collection year variables.
 - The payment_year_var has been set in the model so it gets compiled.
 - The collection year is one year prior to the payment year.
*/
{% set payment_year_compiled = var('payment_year') -%}

with professional_conditions as (

    select
          claim_id
        , claim_line_number
        , claim_type
        , patient_id
        , claim_start_date
        , claim_end_date
        , hcpcs_code
        , condition_code
    from {{ ref('cms_hcc__stg_professional_condition') }}

),

hcc_mapping as (

    select
          diagnosis_code
        , cms_hcc_v24 as hcc_code
    from {{ ref('cms_hcc__icd_10_cm_mappings') }}
    where payment_year = {{ payment_year_compiled }}
    and cms_hcc_v24_flag = 'Yes'

),

mapped as (

    select distinct
          professional_conditions.patient_id
        , professional_conditions.condition_code
        , hcc_mapping.hcc_code
    from professional_conditions
         inner join hcc_mapping
         on professional_conditions.condition_code = hcc_mapping.diagnosis_code

)

select * from mapped