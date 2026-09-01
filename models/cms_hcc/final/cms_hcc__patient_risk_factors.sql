{{ config(
     enabled = var('claims_enabled', False) | as_bool
   )
}}

with monthly as (

    select
          *
        , max(collection_end_date) over (
              partition by person_id, payer, data_source, payment_year
          ) as latest_collection_end_date
    from {{ ref('cms_hcc__patient_risk_factors_monthly') }}
    where payment_year = {{ var('cms_hcc_payment_year') }}

)

select
      person_id
    , payer
    , data_source
    , enrollment_status_default
    , medicaid_dual_status_default
    , orec_default
    , institutional_status_default
    , factor_type
    , risk_factor_description
    , coefficient
    , model_version
    , payment_year
    , cast('{{ var('tuva_last_run') }}' as {{ dbt.type_timestamp() }}) as tuva_last_run
from monthly
where collection_end_date = latest_collection_end_date
