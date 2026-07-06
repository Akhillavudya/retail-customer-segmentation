-- Genuinely loyal vs promo-driven buyers.
-- Separates customers who buy regardless of discounts from bargain hunters,
-- so promo spend can be protected. Ports Key Question 1A.

select
    case
        when is_loyal_value_sat = 1 and promo_dependency_score < 50
            then 'Genuinely Loyal'
        when is_loyal_value_sat = 0 and promo_dependency_score = 100
            then 'Promo-Only Buyers'
        when promo_dependency_score between 50 and 99
            then 'Promo-Influenced'
        else 'Low-Engagement'
    end                                                         as buyer_type,
    count(*)                                                    as customers,
    round(count(*) * 100.0 / sum(count(*)) over (), 1)          as pct_of_base,
    round(avg(purchase_amount_usd), 2)                          as avg_spend,
    round(avg(previous_purchases), 1)                           as avg_prev_purchases,
    round(avg(review_rating), 2)                                as avg_rating,
    round(avg(estimated_annual_revenue), 2)                     as avg_annual_revenue,
    round(avg(value_score), 2)                                  as avg_value_score
from {{ ref('stg_customers') }}
group by buyer_type
order by avg_annual_revenue desc
