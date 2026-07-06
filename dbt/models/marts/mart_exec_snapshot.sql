-- Executive snapshot: single-row business overview for the dashboard header.
-- Scale, loyalty health, promo exposure, satisfaction, revenue concentration.
-- Ports the BONUS executive-overview query.

select
    count(*)                                                    as total_customers,
    round(sum(estimated_annual_revenue), 0)                     as total_est_annual_revenue,
    round(avg(purchase_amount_usd), 2)                          as avg_basket_size,
    round(avg(previous_purchases), 1)                           as avg_tenure_purchases,

    round(sum(is_loyal_value_sat) * 100.0 / count(*), 1)        as pct_loyal,
    round(sum(case when customer_segment = 'Organic Champions'
                   then 1 else 0 end) * 100.0 / count(*), 1)    as pct_organic_champions,

    round(avg(promo_dependency_score), 1)                       as avg_promo_dependency,
    round(sum(case when promo_dependency_score = 100
                   then 1 else 0 end) * 100.0 / count(*), 1)    as pct_fully_promo_dependent,
    round(sum(case when promo_dependency_score = 0
                   then 1 else 0 end) * 100.0 / count(*), 1)    as pct_fully_organic,

    round(avg(review_rating), 2)                                as avg_review_rating,
    round(avg(satisfaction_flag) * 100, 1)                      as pct_satisfied,

    round((select sum(estimated_annual_revenue) from {{ ref('stg_customers') }}
             where value_tier = 'Champions')
          * 100.0 / sum(estimated_annual_revenue), 1)           as champions_rev_share_pct
from {{ ref('stg_customers') }}
