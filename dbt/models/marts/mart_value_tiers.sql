-- Value-tier summary: behavioral profile + revenue concentration per tier.
-- Answers "who drives the revenue?" — Champions ~49.7% at ~25% of customers.
-- Ports Key Question 1B / 2A from sql/segmentation_analysis.sql.

select
    value_tier,
    count(*)                                                    as customers,
    round(count(*) * 100.0 / sum(count(*)) over (), 1)          as pct_of_base,
    round(avg(purchase_amount_usd), 2)                          as avg_spend,
    round(avg(previous_purchases), 1)                           as avg_prev_purchases,
    round(avg(purchase_frequency_per_year), 1)                  as avg_freq_per_year,
    round(avg(promo_dependency_score), 1)                       as avg_promo_dependency,
    round(avg(satisfaction_flag) * 100, 1)                      as pct_satisfied,
    round(avg(subscription_status_flag) * 100, 1)               as pct_subscribed,
    round(sum(estimated_annual_revenue), 0)                     as total_annual_revenue,
    round(avg(estimated_annual_revenue), 0)                     as avg_annual_revenue,
    round(sum(estimated_annual_revenue) * 100.0
          / sum(sum(estimated_annual_revenue)) over (), 1)      as revenue_share_pct
from {{ ref('stg_customers') }}
group by value_tier
order by avg_annual_revenue desc
