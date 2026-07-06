-- Ideal Customer Profile: statistical portrait of the Champions tier.
-- One-row profile used to target lookalike acquisition. Ports Key Question 5A.

select
    'Ideal Customer Profile'                                    as profile,
    round(avg(age), 0)                                          as avg_age,
    (select gender from {{ ref('stg_customers') }}
       where value_tier = 'Champions'
       group by gender order by count(*) desc limit 1)         as dominant_gender,
    (select age_band from {{ ref('stg_customers') }}
       where value_tier = 'Champions'
       group by age_band order by count(*) desc limit 1)       as top_age_band,
    round(avg(purchase_amount_usd), 2)                          as avg_spend,
    round(avg(previous_purchases), 1)                           as avg_prev_purchases,
    round(avg(purchase_frequency_per_year), 1)                  as avg_freq_per_year,
    round(avg(promo_dependency_score), 1)                       as avg_promo_dependency,
    round(avg(review_rating), 2)                                as avg_rating,
    round(avg(estimated_annual_revenue), 0)                     as avg_annual_revenue,
    (select payment_method from {{ ref('stg_customers') }}
       where value_tier = 'Champions'
       group by payment_method order by count(*) desc limit 1) as top_payment_method,
    (select shipping_type from {{ ref('stg_customers') }}
       where value_tier = 'Champions'
       group by shipping_type order by count(*) desc limit 1)  as preferred_shipping,
    (select category from {{ ref('stg_customers') }}
       where value_tier = 'Champions'
       group by category order by count(*) desc limit 1)       as top_category,
    (select season from {{ ref('stg_customers') }}
       where value_tier = 'Champions'
       group by season order by count(*) desc limit 1)         as peak_season
from {{ ref('stg_customers') }}
where value_tier = 'Champions'
