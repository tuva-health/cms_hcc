{% snapshot cms_hcc__patient_risk_scores_snapshot %}

{{
  config({
      "target_schema": "cms_hcc"
    , "alias": "patient_risk_scores_snapshot"
    , "tags": "cms_hcc"
    , "strategy": "timestamp"
    , "updated_at": "date_calculated"
    , "unique_key": "patient_id||raw_risk_score||normalized_risk_score||payment_risk_score||model_version||payment_year||date_calculated"
  })
}}

select * from {{ ref('cms_hcc__patient_risk_scores') }}

{% endsnapshot %}