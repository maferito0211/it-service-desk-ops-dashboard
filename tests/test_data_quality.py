import os
import pandas as pd
import sqlalchemy as sa
from dotenv import load_dotenv

load_dotenv()

SCHEMA = "itsm"

def get_engine() -> sa.Engine:
    host = os.getenv("PGHOST", "localhost")
    port = os.getenv("PGPORT", "5432")
    db = os.getenv("PGDATABASE", "itsm_analytics")
    user = os.getenv("PGUSER", "postgres")
    pw = os.getenv("PGPASSWORD", "")
    if not pw:
        raise RuntimeError("PGPASSWORD is missing. Add it to .env or environment variables.")
    url = f"postgresql+psycopg2://{user}:{pw}@{host}:{port}/{db}"
    return sa.create_engine(url, future=True)

def q(engine: sa.Engine, sql: str) -> int:
    with engine.connect() as conn:
        return conn.execute(sa.text(sql)).scalar_one()

def test_fact_row_count_is_100k():
    engine = get_engine()
    n = q(engine, f"SELECT COUNT(*) FROM {SCHEMA}.fact_ticket;")
    assert n == 100000, f"Expected 100000 rows in fact_ticket, got {n}"

def test_ticket_id_unique():
    engine = get_engine()
    dupes = q(engine, f"""
        SELECT COUNT(*) FROM (
            SELECT ticket_id
            FROM {SCHEMA}.fact_ticket
            GROUP BY ticket_id
            HAVING COUNT(*) > 1
        ) d;
    """)
    assert dupes == 0, f"Expected no duplicate ticket_id, found {dupes}"

def test_ticket_id_not_null():
    engine = get_engine()
    nulls = q(engine, f"SELECT COUNT(*) FROM {SCHEMA}.fact_ticket WHERE ticket_id IS NULL;")
    assert nulls == 0, f"Expected ticket_id non-null, found {nulls} nulls"

def test_timestamp_chronology_order():
    engine = get_engine()
    bad = q(engine, f"""
        SELECT COUNT(*)
        FROM {SCHEMA}.fact_ticket
        WHERE NOT (
            created_time <= first_response_time
            AND first_response_time <= resolution_time
            AND resolution_time <= close_time
        );
    """)
    assert bad == 0, f"Expected 0 chronology violations, found {bad}"

def test_no_negative_durations():
    engine = get_engine()
    bad = q(engine, f"""
        SELECT COUNT(*)
        FROM {SCHEMA}.fact_ticket
        WHERE first_response_minutes < 0 OR resolution_minutes < 0;
    """)
    assert bad == 0, f"Expected 0 negative durations, found {bad}"

def test_dimension_counts_match_dictionary():
    engine = get_engine()
    # Expected from your data dictionary:
    exp = {
        "dim_priority": 4,
        "dim_status": 5,
        "dim_agent_group": 5,
        "dim_topic": 5,
        "dim_country": 6,
        "dim_support_level": 3,
    }
    for table, expected in exp.items():
        got = q(engine, f"SELECT COUNT(*) FROM {SCHEMA}.{table};")
        assert got == expected, f"{table}: expected {expected}, got {got}"

def test_no_orphan_dimension_keys():
    engine = get_engine()
    # Each FK should have a valid dimension row
    orphan_priority = q(engine, f"""
        SELECT COUNT(*)
        FROM {SCHEMA}.fact_ticket f
        LEFT JOIN {SCHEMA}.dim_priority d ON f.priority_id = d.priority_id
        WHERE d.priority_id IS NULL;
    """)
    assert orphan_priority == 0, f"Orphan priority_id rows: {orphan_priority}"

    orphan_status = q(engine, f"""
        SELECT COUNT(*)
        FROM {SCHEMA}.fact_ticket f
        LEFT JOIN {SCHEMA}.dim_status d ON f.status_id = d.status_id
        WHERE d.status_id IS NULL;
    """)
    assert orphan_status == 0, f"Orphan status_id rows: {orphan_status}"

def test_backlog_flag_logic_matches_status():
    engine = get_engine()
    # backlog_flag should be true iff status in (New, Open, In Progress)
    mismatches = q(engine, f"""
        SELECT COUNT(*)
        FROM {SCHEMA}.fact_ticket f
        JOIN {SCHEMA}.dim_status s ON f.status_id = s.status_id
        WHERE
            (f.backlog_flag = TRUE AND s.status_name NOT IN ('New','Open','In Progress'))
            OR
            (f.backlog_flag = FALSE AND s.status_name IN ('New','Open','In Progress'));
    """)
    assert mismatches == 0, f"Backlog flag mismatches vs status: {mismatches}"
