"""
IT Service Desk and Support Operations Analytics
Pipeline: Raw CSV -> Processed analytics-ready CSV

Run:
  python src/pipeline/run_pipeline.py

Inputs:
  data/raw/itsm_raw.csv

Outputs:
  data/processed/itsm_clean.csv

What this script does:
- Loads raw ITSM data
- Parses timestamp columns to datetime
- Creates KPI-ready derived columns (durations, SLA flags, backlog, satisfaction score)
- Runs QA checks (duplicates, chronology, SLA reconciliation)
- Saves processed dataset
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import sys
import logging
import pandas as pd


# -----------------------------
# Configuration
# -----------------------------
@dataclass(frozen=True)
class PipelineConfig:
    raw_path: Path = Path("data/raw/itsm_raw.csv")
    processed_path: Path = Path("data/processed/itsm_clean.csv")

    # Time columns to parse (raw CSV contains these as strings)
    time_cols: tuple[str, ...] = (
        "Created time",
        "First response time",
        "Resolution time",
        "Close time",
        "Expected SLA to first response",
        "Expected SLA to resolve",
    )

    # Backlog statuses definition (business rule)
    backlog_statuses: tuple[str, ...] = ("New", "Open", "In Progress")

    # Satisfaction mapping (for numeric analysis)
    satisfaction_map: dict[str, int] = None  # set in __post_init__ below


def build_config() -> PipelineConfig:
    # dataclass with a small trick so mapping isn't a mutable default argument
    cfg = PipelineConfig()
    object.__setattr__(cfg, "satisfaction_map", {"Satisfied": 3, "Neutral": 2, "Dissatisfied": 1})
    return cfg


# -----------------------------
# Logging
# -----------------------------
def setup_logger() -> logging.Logger:
    logger = logging.getLogger("itsm_pipeline")
    logger.setLevel(logging.INFO)

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.INFO)

    formatter = logging.Formatter("[%(levelname)s] %(message)s")
    handler.setFormatter(formatter)

    if not logger.handlers:
        logger.addHandler(handler)

    return logger


# -----------------------------
# Pipeline steps
# -----------------------------
def load_raw(cfg: PipelineConfig, logger: logging.Logger) -> pd.DataFrame:
    logger.info(f"Loading raw data: {cfg.raw_path}")
    if not cfg.raw_path.exists():
        raise FileNotFoundError(f"Raw file not found: {cfg.raw_path.resolve()}")

    df = pd.read_csv(cfg.raw_path)
    logger.info(f"Loaded shape: {df.shape[0]} rows, {df.shape[1]} columns")
    df.columns = df.columns.str.strip()
    return df


def parse_timestamps(df: pd.DataFrame, cfg: PipelineConfig, logger: logging.Logger) -> pd.DataFrame:
    logger.info("Parsing timestamp columns to datetime")
    for col in cfg.time_cols:
        if col not in df.columns:
            raise KeyError(f"Missing required time column: '{col}'")
        df[col] = pd.to_datetime(df[col], errors="raise")

    missing = df[list(cfg.time_cols)].isna().sum()
    if int(missing.sum()) != 0:
        raise ValueError(f"Timestamp parsing introduced missing values:\n{missing}")
    logger.info("Timestamp parsing OK (no missing timestamps)")
    return df


def create_derived_columns(df: pd.DataFrame, cfg: PipelineConfig, logger: logging.Logger) -> pd.DataFrame:
    logger.info("Creating derived KPI-ready columns")

    # Duration metrics (minutes)
    df["first_response_minutes"] = (df["First response time"] - df["Created time"]).dt.total_seconds() / 60
    df["resolution_minutes"] = (df["Resolution time"] - df["Created time"]).dt.total_seconds() / 60

    # SLA compliance recalculation using deadlines (timestamp-based SLA)
    df["response_sla_met_recalc"] = df["First response time"] <= df["Expected SLA to first response"]
    df["resolution_sla_met_recalc"] = df["Resolution time"] <= df["Expected SLA to resolve"]

    # Provided SLA labels converted to booleans for reconciliation QA
    df["response_sla_flag_bool"] = df["SLA For first response"].astype(str).str.strip().eq("Met")
    df["resolution_sla_flag_bool"] = df["SLA For Resolution"].astype(str).str.strip().eq("Met")

    # Backlog flag (business rule)
    df["backlog_flag"] = df["Status"].astype(str).str.strip().isin(cfg.backlog_statuses)

    # Satisfaction score
    df["satisfaction_score"] = df["Survey results"].map(cfg.satisfaction_map)

    # Guard: satisfaction mapping should not produce nulls
    if df["satisfaction_score"].isna().any():
        bad = df.loc[df["satisfaction_score"].isna(), "Survey results"].value_counts()
        raise ValueError(
            "Satisfaction mapping produced missing values. Unexpected 'Survey results' categories:\n"
            f"{bad}"
        )

    logger.info("Derived columns created successfully")
    return df


def run_qa_checks(df: pd.DataFrame, cfg: PipelineConfig, logger: logging.Logger) -> None:
    logger.info("Running QA checks")

    # 1) Primary key duplicates
    dup_ticket_ids = int(df.duplicated(subset=["Ticket ID"]).sum())
    if dup_ticket_ids != 0:
        raise ValueError(f"Duplicate Ticket ID detected: {dup_ticket_ids}")
    logger.info("QA: Ticket ID uniqueness OK")

    # 2) Duration integrity
    neg_first = int((df["first_response_minutes"] < 0).sum())
    neg_res = int((df["resolution_minutes"] < 0).sum())
    if neg_first != 0 or neg_res != 0:
        raise ValueError(
            f"Negative duration(s) found. first_response_minutes={neg_first}, resolution_minutes={neg_res}"
        )
    logger.info("QA: Duration integrity OK (no negatives)")

    # 3) Chronological integrity
    bad_created_to_response = int((df["First response time"] < df["Created time"]).sum())
    bad_response_to_resolution = int((df["Resolution time"] < df["First response time"]).sum())
    bad_resolution_to_close = int((df["Close time"] < df["Resolution time"]).sum())

    if bad_created_to_response or bad_response_to_resolution or bad_resolution_to_close:
        raise ValueError(
            "Chronological integrity failed:\n"
            f"- First response before Created: {bad_created_to_response}\n"
            f"- Resolution before First response: {bad_response_to_resolution}\n"
            f"- Close before Resolution: {bad_resolution_to_close}"
        )
    logger.info("QA: Chronological integrity OK")

    # 4) SLA reconciliation (provided labels vs recalculated boolean)
    response_match = (df["response_sla_met_recalc"] == df["response_sla_flag_bool"])
    resolution_match = (df["resolution_sla_met_recalc"] == df["resolution_sla_flag_bool"])

    response_mismatch = int((~response_match).sum())
    resolution_mismatch = int((~resolution_match).sum())

    if response_mismatch != 0 or resolution_mismatch != 0:
        raise ValueError(
            "SLA reconciliation failed:\n"
            f"- Response SLA mismatches: {response_mismatch}\n"
            f"- Resolution SLA mismatches: {resolution_mismatch}"
        )
    logger.info("QA: SLA reconciliation OK (recalc matches provided labels)")

    # 5) Quick KPI snapshot (log only)
    logger.info("KPI snapshot (sanity checks):")
    logger.info(f"- Tickets total: {len(df)}")
    logger.info(f"- First response median (min): {float(df['first_response_minutes'].median()):.2f}")
    logger.info(f"- Resolution median (min): {float(df['resolution_minutes'].median()):.2f}")
    logger.info(f"- Open backlog tickets: {int(df['backlog_flag'].sum())}")
    logger.info(f"- Avg satisfaction score: {float(df['satisfaction_score'].mean()):.2f}")
    logger.info(f"- Response SLA rate (recalc): {float(df['response_sla_met_recalc'].mean()):.4f}")
    logger.info(f"- Resolution SLA rate (recalc): {float(df['resolution_sla_met_recalc'].mean()):.4f}")

    logger.info("All QA checks passed")


def save_processed(df: pd.DataFrame, cfg: PipelineConfig, logger: logging.Logger) -> None:
    cfg.processed_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(cfg.processed_path, index=False)
    logger.info(f"Saved processed dataset: {cfg.processed_path}")


def main() -> int:
    logger = setup_logger()
    cfg = build_config()

    try:
        df = load_raw(cfg, logger)
        df = parse_timestamps(df, cfg, logger)
        df = create_derived_columns(df, cfg, logger)
        run_qa_checks(df, cfg, logger)
        save_processed(df, cfg, logger)
        logger.info("Pipeline completed successfully")
        return 0

    except Exception as exc:
        logger.error(f"Pipeline failed: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
