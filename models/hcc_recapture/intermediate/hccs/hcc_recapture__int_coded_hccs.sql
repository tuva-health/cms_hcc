{{ config(
     enabled = var('claims_enabled', False) | as_bool
   )
}}

with eligible_claims as (
-- Use distinct to remove claim line
    select distinct
        person_id
        , claim_id
        , payer
    from {{ ref('cms_hcc__int_eligible_conditions') }}
)

select
    cond.person_id
    , cond.payer
    , cond.data_source
    , cond.recorded_date
    , cond.model_version
    , cond.claim_id
    , cond.hcc_code
    , cond.hcc_description
    , 0 as suspect_hcc_flag
    , case
        when elig.claim_id is not null then 1
        else 0
    end as eligible_claim_flag
    , 'prior coding history' as reason
    , 'coded' as hcc_type
    , 'payer' as hcc_source
-- Not using list_all since it doesn't have claim_id pulled through
-- TODO: Update hcc_suspecting__list_all to have claim ID as well
from {{ ref('hcc_suspecting__int_all_conditions') }} as cond
left join eligible_claims as elig
    on cond.person_id = elig.person_id
    and cond.payer = elig.payer
    and cond.claim_id = elig.claim_id
-- Tuva Core 1.0 labels claims-derived conditions as billing diagnoses because
-- professional claims do not establish a discharge diagnosis. Retain the
-- clinical discharge-diagnosis value as a supported coded-condition source.
where lower(condition_type) in ('billing_diagnosis', 'discharge_diagnosis')
