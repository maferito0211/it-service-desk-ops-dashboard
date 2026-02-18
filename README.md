# IT Service Desk & Support Operations Analytics Dashboard

## Overview

This project is an end-to-end analytics solution for IT service desk operations using a synthetic ITSM dataset (100,000 tickets).  
It models the ticket lifecycle (created → first response → resolved → closed), recalculates SLA compliance from timestamps, and delivers an executive-ready Power BI dashboard focused on SLA performance and backlog health.

## What This Solves (Business Questions)

- Are we meeting response and resolution SLAs?
- Is backlog under control, and how old is the backlog?
- Which topics and teams drive workload and longer resolution times?
- Can stakeholders trust the numbers (data quality checks and definitions)?

## Tech Stack

- **Python**: ETL pipeline, validation, feature engineering
- **PostgreSQL**: star schema (warehouse-style), KPI queries, indexed fact table
- **Power BI**: interactive dashboard (filters, KPIs, trend + breakdown views)
- **pytest**: automated data quality + KPI reconciliation tests
- **Git/GitHub**: version control and reproducibility

## Dataset

- **Rows**: 100,000 tickets
- **Raw file**: `data/raw/itsm_raw.csv`
- **Processed file**: `data/processed/itsm_clean.csv`
- Includes ticket lifecycle timestamps, SLA deadline timestamps, status/priority, agent group, topic, satisfaction, and geo fields.

## Data Model (PostgreSQL Star Schema)

- **Fact table**: `itsm.fact_ticket`
- **Dimensions**:
  - `itsm.dim_priority`
  - `itsm.dim_status`
  - `itsm.dim_agent_group`
  - `itsm.dim_topic`
  - `itsm.dim_country`
  - `itsm.dim_support_level`

This structure supports enterprise-style BI filtering (Priority, Queue/Agent Group, Topic, Country, Support Level).

## Key Metrics (Examples)

- Ticket Volume (total, created/resolved trend)
- Backlog (Status in New/Open/In Progress)
- SLA Compliance % (response + resolution, recalculated from timestamps)
- Median Resolution Time (robust to outliers)
- Backlog Aging Buckets (0–7, 8–14, 15–30, 30+ days)

## Data Quality & Validation

Automated QA checks were implemented in Python and validated in the database layer:

- **Duplicate Ticket IDs**: 0
- **Negative durations**: 0
- **Timestamp chronology**: created ≤ first response ≤ resolution ≤ close
- **SLA reconciliation**: recalculated SLA flags match expected behavior

See:

- `tests/test_data_quality.py`
- `tests/test_kpi_reconciliation.py`

## Dashboard (Power BI)

The Power BI report includes 3 pages:

1. **Executive Overview** — SLA performance, backlog health, trends, backlog aging
2. **SLA & Operational Drivers** — SLA by priority, volume by topic, median resolution by team/topic
3. **Data Quality & Definitions** — QA cards + KPI definitions for stakeholder trust

> File: `dashboard/IT_Service_Desk_Dashboard.pbix`

## Project Structure

it-service-desk-ops-dashboard/
├─ README.md
├─ requirements.txt
├─ LICENSE
├─ .gitignore
├─ .env
├─ data/
│ ├─ raw/
│ │ └─ itsm_raw.csv
│ └─ processed/
│ └─ itsm_clean.csv
├─ docs/
│ ├─ data_dictionary.md
│ ├─ assumptions.md
│ ├─ data_dictionary_values_catalog.csv
│ ├─ kpi_definitions.md
│ ├─ qa_test_cases.md
│ ├─ requirements.md
│ └─ stakeholder_questions.md
├─ notebooks/
│ └─ 01_profile.ipynb
├─ src/
│ └─ pipeline/
│ └─ run_pipeline.py
├─ sql/
│ ├─ 01_schema.sql
│ ├─ 02_load.sql
│ └─ 03_kpi_queries.sql
├─ tests/
│ ├─ test_data_quality.py
│ └─ test_kpi_reconciliation.py
└─ dashboard/
└─ IT_Service_Desk_Dashboard.pbix

## How to Run (Quick Start)

### 1) Create the database + tables

Run in pgAdmin (Query Tool) or `psql`:

- `sql/01_schema.sql`

### 2) Load data

Use the staging + load script:

- `sql/02_load.sql`

(Ensure the CSV path in the COPY command points to your local `data/processed/itsm_clean.csv`.)

### 3) Run KPI SQL (optional)

- `sql/03_kpi_queries.sql`

### 4) Run tests (Day 5 validation)

Create a `.env` file in the project root:

## How to Run (Quick Start)

### 1) Create the database + tables

Run in pgAdmin (Query Tool) or `psql`:

- `sql/01_schema.sql`

### 2) Load data

Use the staging + load script:

- `sql/02_load.sql`

(Ensure the CSV path in the COPY command points to your local `data/processed/itsm_clean.csv`.)

### 3) Run KPI SQL (optional)

- `sql/03_kpi_queries.sql`

### 4) Run tests (Day 5 validation)

Create a `.env` file in the project root:
PGHOST=localhost
PGPORT=5432
PGDATABASE=itsm_analytics
PGUSER=postgres
PGPASSWORD=your_password_here

Install dependencies:

- ```bash
  pip install -r requirements.txt
  ```

Run:
python -m pytest -q

### 5) Open the dashboard

Open:

dashboard/IT_Service_Desk_Dashboard.pbix

Connect to your local PostgreSQL database if prompted.

## Notes / Limitations

This project uses a synthetic dataset designed to mimic realistic ITSM behavior.

SLA labels provided in the source data were independently validated against timestamp-based calculations to ensure metric integrity.

## License

Add your preferred license (MIT recommended for public portfolios).
