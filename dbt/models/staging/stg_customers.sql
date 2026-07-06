-- Staging model: typed, explicit view over the enriched customer file.
-- Reads data/processed/customers_enriched.csv (3,900 rows x 31 cols) produced
-- by notebooks/01_feature_engineering.ipynb. Every mart references this model.

with source as (
    select * from read_csv_auto('{{ var("enriched_csv") }}')
)

select
    customer_id,
    age,
    gender,
    item_purchased,
    category,
    purchase_amount_usd,
    location,
    "size"                          as apparel_size,
    color,
    season,
    review_rating,
    subscription_status,
    shipping_type,
    discount_applied,
    promo_code_used,
    previous_purchases,
    payment_method,
    frequency_of_purchases,
    subscription_status_flag,
    discount_applied_flag,
    promo_code_used_flag,
    purchase_frequency_per_year,
    age_band,
    promo_dependency_score,
    value_score,
    value_tier,
    satisfaction_flag,
    is_loyal_behavioral,
    is_loyal_value_sat,
    estimated_annual_revenue,
    customer_segment
from source
