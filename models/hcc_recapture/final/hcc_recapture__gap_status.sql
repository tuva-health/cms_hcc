{{ config(
     enabled = var('claims_enabled', False) | as_bool
   )
}}

-- Using distinct to remove the hierarchy group and data source
select distinct
      person_id
    , payer
    , hcc_code
    , closing_hcc_code
    , gap_hcc_code
    , best_current_year_hcc_code
    , risk_model_code
    , model_version
    , payment_year
    , recapturable_flag
    , hcc_type
    , hcc_source
    , gap_status
    , suspect_hcc_flag
from {{ ref('hcc_recapture__int_gap_status')}}
-- Apply hierarchies
where filtered_by_hierarchy_flag = 0
