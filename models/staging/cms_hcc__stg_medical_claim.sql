{{ config(enabled = var('cms_hcc_enabled',var('tuva_packages_enabled',True)) ) -}}

/*
Steps for staging the medical claim data:
    1) Filter to risk-adjustable claims per claim type for the collection year.
    2) Gather diagnosis codes from condition for the eligible claims.
    3) Map and filter diagnosis codes to HCCs

Claims filtering logic:
 - Professional:
    - CPT/HCPCS in CPT/HCPCS seed file from CMS
 - Inpatient:
    - Bill type code in (11X, 41X)
 - Outpatient:
    - Bill type code in (12X, 13X, 43X, 71X, 73X, 76X, 77X, 85X)
    - CPT/HCPCS in CPT/HCPCS seed file from CMS

Jinja is used to set payment and collection year variables.
 - The hcc_model_version and payment_year vars have been set here
   so they get compiled.
 - The collection year is one year prior to the payment year.
*/
{% set model_version_compiled = var('hcc_model_version') -%}
{% set payment_year_compiled = var('payment_year') -%}
{% set collection_year = payment_year_compiled - 1 -%}

with medical_claim_src as (

    select
          claim_id
        , claim_line_number
        , claim_type
        , patient_id
        , claim_start_date
        , claim_end_date
        , bill_type_code
        , hcpcs_code
    from {{ var('medical_claim') }}

)

, cpt_hcpcs_list as (

    select
          payment_year
        , hcpcs_cpt_code
    from {{ ref('cms_hcc__cpt_hcpcs') }}

)

, professional_claims as (

    select
          medical_claim_src.claim_id
        , medical_claim_src.claim_line_number
        , medical_claim_src.claim_type
        , medical_claim_src.patient_id
        , medical_claim_src.claim_start_date
        , medical_claim_src.claim_end_date
        , medical_claim_src.bill_type_code
        , medical_claim_src.hcpcs_code
        , '{{ model_version_compiled }}' as model_version
        , '{{ payment_year_compiled }}' as payment_year
        , getdate() as date_calculated
    from medical_claim_src
         inner join cpt_hcpcs_list
         on medical_claim_src.hcpcs_code = cpt_hcpcs_list.hcpcs_cpt_code
    where claim_type = 'professional'
    and year(claim_end_date) = '{{ collection_year }}'
    and cpt_hcpcs_list.payment_year = '{{ payment_year_compiled }}'

)

, inpatient_claims as (

    select
          medical_claim_src.claim_id
        , medical_claim_src.claim_line_number
        , medical_claim_src.claim_type
        , medical_claim_src.patient_id
        , medical_claim_src.claim_start_date
        , medical_claim_src.claim_end_date
        , medical_claim_src.bill_type_code
        , medical_claim_src.hcpcs_code
        , '{{ model_version_compiled }}' as model_version
        , '{{ payment_year_compiled }}' as payment_year
        , getdate() as date_calculated
    from medical_claim_src
    where claim_type = 'institutional'
    and year(claim_end_date) = '{{ collection_year }}'
    and left(bill_type_code,2) in ('11','41')

)

, outpatient_claims as (

    select
          medical_claim_src.claim_id
        , medical_claim_src.claim_line_number
        , medical_claim_src.claim_type
        , medical_claim_src.patient_id
        , medical_claim_src.claim_start_date
        , medical_claim_src.claim_end_date
        , medical_claim_src.bill_type_code
        , medical_claim_src.hcpcs_code
        , '{{ model_version_compiled }}' as model_version
        , '{{ payment_year_compiled }}' as payment_year
        , getdate() as date_calculated
    from medical_claim_src
         inner join cpt_hcpcs_list
         on medical_claim_src.hcpcs_code = cpt_hcpcs_list.hcpcs_cpt_code
    where claim_type = 'institutional'
    and year(claim_end_date) = '{{ collection_year }}'
    and cpt_hcpcs_list.payment_year = '{{ payment_year_compiled }}'
    and left(bill_type_code,2) in ('12','13','43','71','73','76','77','85')

)

, unioned as (

    select * from professional_claims
    union all
    select * from inpatient_claims
    union all
    select * from outpatient_claims

)

select * from unioned