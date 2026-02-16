import os
import pandas as pd
import sqlalchemy as sa
from dotenv import load_dotenv

load_dotenv()

SCHEMA = "itsm"
CSV_PATH = os.path.join("data", "processed", "itsm_clean.csv")

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

def sql_scalar(engine: sa.Engine, sql: str):
    with engine.connect() as conn:
        return conn.execute(sa.text(sql)).scalar_one()

def test_total_tickets_matches_csv():
    df = pd.read_csv(CSV_PATH)
    py_total = int(df.shape[0])

    engine = get_engine()
    db_total = int(sql_scalar(engine, f"SELECT COUNT(*) FROM {SCHEMA}.fact_ticket;"))

    assert db_total == py_total == 100000, f"Expected 100000, got db={db_total}, csv={py_total}"

def test_sla_compliance_matches_csv():
    df = pd.read_csv(CSV_PATH)

    # CSV columns created by pipeline
    py_resp = float((df["response_sla_flag_bool"] == True).mean() * 100.0)
    py_reso = float((df["resolution_sla_flag_bool"] == True).mean() * 100.0)

    engine = get_engine()
    db_resp = float(sql_scalar(engine, f"""
        SELECT 100.0 * AVG((response_sla_flag_bool)::int)
        FROM {SCHEMA}.fact_ticket;
    """))
    db_reso = float(sql_scalar(engine, f"""
        SELECT 100.0 * AVG((resolution_sla_flag_bool)::int)
        FROM {SCHEMA}.fact_ticket;
    """))

    # Exact match expected given your pipeline QA said 100% match
    assert abs(db_resp - py_resp) < 1e-9, f"Response SLA mismatch db={db_resp} csv={py_resp}"
    assert abs(db_reso - py_reso) < 1e-9, f"Resolution SLA mismatch db={db_reso} csv={py_reso}"

def test_median_resolution_minutes_matches_csv():
    df = pd.read_csv(CSV_PATH)
    py_median = float(df["resolution_minutes"].median())

    engine = get_engine()
    db_median = float(sql_scalar(engine, f"""
        SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_minutes)
        FROM {SCHEMA}.fact_ticket;
    """))

    # Medians should match closely (allow tiny numeric differences)
    assert abs(db_median - py_median) < 1e-6, f"Median resolution mismatch db={db_median} csv={py_median}"

def test_satisfaction_rate_matches_csv():
    df = pd.read_csv(CSV_PATH)
    py_rate = float((df["satisfaction_score"] == 3).mean() * 100.0)

    engine = get_engine()
    db_rate = float(sql_scalar(engine, f"""
        SELECT 100.0 * AVG((satisfaction_score = 3)::int)
        FROM {SCHEMA}.fact_ticket;
    """))

    assert abs(db_rate - py_rate) < 1e-9, f"Satisfaction rate mismatch db={db_rate} csv={py_rate}"
