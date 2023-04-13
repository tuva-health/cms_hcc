{{ config(enabled = var('cms_hcc_enabled',var('tuva_packages_enabled',True)) ) -}}

with claim as (

    select
          claim_id
        , patient_id
        , model_version
        , payment_year
    from {{ ref('cms_hcc__stg_medical_claim') }}

)

, condition as (

    select
          claim_id
        , patient_id
        , code
    from {{ var('condition') }}
    where code_type = 'icd-10-cm'

)

, joined as (

    select distinct
          claim.claim_id
        , claim.patient_id
        , condition.code as condition_code
        , model_version
        , payment_year
    from claim
         inner join condition
         on claim.claim_id = condition.claim_id
         and claim.patient_id = condition.patient_id

)

select * from joined