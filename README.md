# Retail Customer Segmentation & Intelligence

**Segmenting 3,900 retail shoppers by value and promo-dependency to tell genuinely loyal customers from discount-driven bargain hunters — so the business protects the right customers and stops over-spending on promotions.**

An end-to-end analytics project: Python feature engineering → tested SQL models (dbt + DuckDB) → BI dashboards (Power BI + Tableau Public) → executive deliverables.

> **Live dashboard:** _Tableau Public link goes here once published_ · **Dashboards:** [`dashboards/`](dashboards/) · **Business reports:** [`reports/`](reports/)

---

## Headline findings

| # | Finding | Number |
|---|---------|--------|
| 1 | **Revenue is highly concentrated** — the top value tier (Champions) drives nearly half of revenue at a quarter of the base (Pareto). | **Champions = 49.7% of revenue @ 25% of customers** |
| 2 | Total estimated annual revenue across the base. | **$4.05M** |
| 3 | The base is split almost evenly between promo-reliant and organic buyers. | **43% avg promo-dependency · 57% fully organic** |
| 4 | Satisfaction (review rating ≥ 4.0) is the minority. | **41.9% satisfied** |
| 5 | Two loyalty definitions (behavioral vs value-satisfaction) agree most of the time. | **16.1% / 21.3% loyal · 75.6% agreement** |

**Ideal customer profile (Champions):** ~45 y/o, avg spend **$77**, ~38 prior purchases, ~28 purchases/yr, **$2,067** est. annual revenue, top category *Clothing*, peak season *Winter*.

_All figures are reproduced by the code in this repo — see the dbt marts and the notebook output._

---

## Architecture

```
Dataset.csv (3,900 x 18)                      data/raw/
        │
        ▼  Python cleaning + feature engineering
notebooks/01_feature_engineering.ipynb
        │   • median-impute 37 null ratings   • encode Yes/No flags
        │   • promo_dependency_score, value_score, value_tier
        │   • satisfaction_flag, 2 loyalty defs, est_annual_revenue, segment
        ▼
customers_enriched.csv (3,900 x 31)           data/processed/
        │
        ▼  dbt + DuckDB — modular, tested SQL
dbt/  stg_customers ─► mart_value_tiers
                   ├─► mart_loyalty_vs_promo
                   ├─► mart_ideal_customer
                   └─► mart_exec_snapshot        (12 schema tests)
        │
        ▼  Business intelligence
dashboards/  Power BI (sqlcna.pbix)  +  Tableau Public
reports/     Executive Summary · Retention Playbook · Query walkthrough
```

Raw analytical SQL (15 queries under 5 business questions) also lives in [`sql/segmentation_analysis.sql`](sql/segmentation_analysis.sql); the dbt models port the key blocks into reproducible, tested marts.

---

## Repository layout

| Path | What's inside |
|------|---------------|
| `data/raw/` | Original `Dataset.csv` (3,900 customers). |
| `data/processed/` | `customers_enriched.csv` — pipeline output (31 columns). |
| `notebooks/` | `01_feature_engineering.ipynb` — clean + feature engineering. |
| `sql/` | `segmentation_analysis.sql` — 15 analytical queries. |
| `dbt/` | dbt project: `stg_customers` + 4 marts + schema tests (DuckDB). |
| `dashboards/powerbi/` | Power BI workbook (`.pbix`) + PDF export. |
| `dashboards/tableau/` | Tableau Public URL + workbook. |
| `reports/` | Executive summary, retention playbook, query walkthrough (PDF). |
| `assets/` | Dashboard screenshots + GIF used in this README. |

---

## How to run

Requires **Python 3.11+**.

```bash
# 1. Install
pip install -r requirements.txt

# 2. Regenerate the enriched dataset (optional — it's already committed)
jupyter nbconvert --to notebook --execute --inplace notebooks/01_feature_engineering.ipynb

# 3. Build + test the SQL models (from the dbt/ directory)
cd dbt
dbt build --profiles-dir .
```

`dbt build` materializes the staging view and four marts into a local DuckDB file and runs all schema tests (expected: `PASS=17`). Inspect a mart:

```bash
python -c "import duckdb; print(duckdb.connect('dbt/dev.duckdb').sql('select * from mart_value_tiers').df())"
```

---

## Tech stack

**Python** (pandas, numpy) · **SQL** · **dbt** + **DuckDB** (tested modular models) · **Power BI** · **Tableau Public**

---

## Team & My Contributions

> Originally built as a **group project** by **[Himanshu Kumar], [Akhil Lavudya]**.
> _(Replace with the real team names before publishing.)_

**My contributions:**
- Contributed to customer segmentation and analytical feature engineering.
- Developed customer value and promo-dependency metrics.
- Contributed SQL analysis for customer segmentation and business insights.
- Supported dbt + DuckDB data modeling and validation.
- Contributed to dashboard development and business reporting.

_Fill these in with what you personally owned — only claim those on your CV._

---

## License

[MIT](LICENSE)
