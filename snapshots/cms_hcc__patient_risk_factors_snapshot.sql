{% snapshot cms_hcc__patient_risk_factors_snapshot %}

{{
  config({
      "target_database": var('cms_hcc_database',var('tuva_database','tuva'))
    , "target_schema": var('cms_hcc_schema','cms_hcc')
    , "alias": "patient_risk_factors_snapshot"
    , "tags": "cms_hcc"
    , "strategy": "timestamp"
    , "updated_at": "date_calculated"
    , "unique_key": "patient_id||enrollment_status_default||medicaid_dual_status_default||institutional_status_default||risk_factor_description||coefficient||model_version||payment_year||date_calculated"
  })
}}

select * from {{ ref('cms_hcc__patient_risk_factors') }}

{% endsnapshot %}