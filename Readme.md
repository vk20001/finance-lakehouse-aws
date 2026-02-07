# AWS Finance Lakehouse

## Overview

The **AWS Finance Lakehouse** is a production-grade, end-to-end data engineering system that models how modern financial data platforms are **built, governed, and operated in practice**.

This is **not a demo** and **not a notebook project**.

The system is intentionally designed to show how a Data Engineer:
- Prevents bad data from propagating
- Enforces grain and contracts
- Treats failures as first-class signals
- Blocks analytics when trust is broken

The focus is **correctness, governance, and containment**, not happy-path analytics.

---

## Architecture

**Cloud:** AWS  
**Core Stack:** S3 · Athena · Glue Data Catalog · dbt (Athena adapter) · Lambda · EventBridge · GitHub Actions · Terraform

### Data Flow (High Level)

- EventBridge schedules ingestion
- Lambda ingests raw financial data into S3
- dbt transforms data through staging → silver → gold
- Athena executes transformations using Glue metadata
- GitHub Actions enforces quality and promotion rules

All infrastructure is provisioned via **Terraform**.  
No manual console configuration.

---

## Data Domains

The lakehouse contains **two independent financial domains**, governed under the same severity framework.

### 1. FRED — Macroeconomic CPI Data

**Source:** Federal Reserve Economic Data (FRED)

Purpose:
- Track CPI time series
- Model data revisions explicitly
- Detect unstable macroeconomic conditions
- Block downstream analytics when assumptions are invalid

Characteristics:
- Revision-aware ingestion
- Control-plane driven promotion
- Gold models intentionally fail when CPI stability is violated

---

### 2. STOOQ — Equity Market Data

**Source:** STOOQ historical equities data

Purpose:
- Clean and standardize OHLCV data
- Enforce strict market-date grain
- Surface market anomalies
- Provide analytics-ready equity aggregates

Characteristics:
- Hard grain enforcement at silver
- Trading-calendar aware transformations
- Anomaly audit and trend models in gold

**Downstream Consumption:**
- Amazon QuickSight dashboards:
  - **Equities Market Overview**
  - **Market Anomaly Trends**

Dashboards consume **gold models only** and rely entirely on upstream promotion gates for trust.

---

## Lakehouse Layers

### Staging Layer

**Responsibility:** Ingestion correctness only

- Raw → typed data
- No business logic
- No assumptions of truth
- Views only (CI-safe for Athena)

---

### Silver Layer

**Responsibility:** Business truth and structural integrity

This is where **data engineering discipline lives**.

Enforced rules:
- Canonical grain per domain
- Required identifiers present
- Structural correctness

**SEV-1 violations block promotion immediately.**

Examples:
- STOOQ: duplicate `(symbol, market_date)` → hard fail
- FRED: missing identifiers or non-numeric CPI values → hard fail

Silver models contain **explicit SQL promotion gates**, not just tests.

---

### Gold Layer

**Responsibility:** Analytics-ready, decision-making data

- Aggregations and metrics
- Audit and anomaly models
- Domain-specific logic

Promotion rules:
- **SEV-2 failures block gold** (business invalid)
- **SEV-3 failures alert only** (monitoring)

Gold models are allowed to **fail by design** when upstream signals indicate unsafe conditions.

---

## Data Quality & Governance Model

This project uses a **severity-based governance framework**, modeled after real production systems.

### Severity Levels

**SEV-1 — Structural / Contract Violations**
- Grain violations
- Missing identifiers
- Schema breaks  
❌ Blocks silver

**SEV-2 — Domain / Business Invalidity**
- CPI revisions invalidate analysis
- Impossible OHLC values  
❌ Blocks gold

**SEV-3 — Anomalies / Monitoring**
- Outliers
- Zero-volume days
- Drift signals  
⚠️ Alert only

**Key principle:**  
Tests detect. Gates enforce.

---

## Control-Plane Pattern (FRED)

The FRED CPI pipeline implements a control-plane architecture:

1. `macro_cpi_diagnostics` evaluates revision stability
2. `macro_cpi_control_plane` emits ALLOW / BLOCK
3. Gold models read the control plane
4. Gold models fail intentionally when state = BLOCKING

This mirrors regulated financial systems where **fresh data is not always safe data**.

---

## CI/CD

### GitHub Actions

Every run executes:
1. dbt compile
2. dbt run
3. dbt tests
4. Promotion gate enforcement

Failures are:
- Deterministic
- Loud
- Non-recoverable without fixing root cause

No manual cleanup. No S3 wipes. No hacks.

### Athena-Safe Design

- Staging models are views
- Silver and gold are tables
- No destructive operations in CI

---

## Infrastructure as Code

All infrastructure is managed via **Terraform**:
- S3 buckets (raw / clean / gold / query)
- IAM roles and policies
- Glue databases and permissions
- Lambda ingestion
- EventBridge schedules

---

## Project Philosophy

This project optimizes for **credibility over convenience**.

It intentionally shows:
- How pipelines fail
- How failures are contained
- How governance is enforced in code
- How analytics are blocked when trust is broken

It intentionally avoids:
- Happy-path demos
- Notebook-centric pipelines
- Silent data corruption
- Over-reliance on tests without enforcement

---

## Status

- Architecture: **Stable**
- Governance model: **Finalized**
- CI/CD: **Operational**
- Domains: **FRED and STOOQ production-grade**
- Orchestration expansion: **Deferred — event-driven design sufficient**

---
