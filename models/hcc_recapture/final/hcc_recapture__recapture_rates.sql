{{ config(
     enabled = var('claims_enabled', False) | as_bool
   )
}}

with monthly_hcc_counts as (
select
      payer
    , data_source
    , payment_year
    , sum(no_suspects_closed_hccs) as no_suspects_closed_hccs
    , sum(no_suspects_open_hccs) as no_suspects_open_hccs
    , sum(no_suspects_total_hccs) as no_suspects_total_hccs
    , sum(closed_hccs) as closed_hccs
    , sum(open_hccs) as open_hccs
    , sum(total_hccs) as total_hccs
from {{ ref('hcc_recapture__recapture_rates_monthly') }}
group by
      payer
    , data_source
    , payment_year
)

select
      payer
    , data_source
    , payment_year
    , no_suspects_closed_hccs
    , no_suspects_open_hccs
    , no_suspects_total_hccs
    , cast(no_suspects_closed_hccs as {{ dbt.type_numeric() }})
        / nullif(cast(no_suspects_total_hccs as {{ dbt.type_numeric() }}), 0) as no_suspects_recapture_rate
    , closed_hccs
    , open_hccs
    , total_hccs
    , cast(closed_hccs as {{ dbt.type_numeric() }})
        / nullif(cast(total_hccs as {{ dbt.type_numeric() }}), 0) as recapture_rate
from monthly_hcc_counts
