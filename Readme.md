# AWS Finance Lakehouse

## Overview

The **AWS Finance Lakehouse** is a production‑grade, end‑to‑end data engineering platform designed to model how modern data teams build, govern, and operate financial analytics systems in the real world.

This project is **not a demo** and **not a notebook exercise**. It intentionally implements industry‑standard patterns for:

* Event‑driven ingestion
* Lakehouse layering (staging → silver → gold)
* Data quality governance with explicit promotion gates
* CI‑enforced correctness using dbt + GitHub Actions
* Clear separation of data engineering vs downstream analytics / ML consumption

The goal is to demonstrate **how a Data Engineer actually thinks in production**: preventing bad data from propagating, enforcing grain and contracts, and treating failures as first‑class citizens.

---

## High‑Level Architecture

**Cloud:** AWS
**Core Stack:** S3 · Athena · Glue Data Catalog · dbt (Athena adapter) · Lambda · EventBridge · GitHub Actions · Terraform

### Data Flow

1. **EventBridge** schedules trigger ingestion
2. **Lambda** functions ingest raw data into S3 (raw layer)
3. **dbt** transforms data through staging → silver → gold layers
4. **Athena + Glue** provide query execution and metadata management
5. **GitHub Actions CI** enforces data quality and promotion rules on every run

All infrastructure (S3, IAM, Glue, Lambda, EventBridge) is provisioned via **Terraform**.

---

## Data Domains

The lakehouse currently supports **two independent financial domains**, treated as equal citizens under a shared governance framework.

### 1. FRED – Macroeconomic CPI Data

**Source:** Federal Reserve Economic Data (FRED)

Purpose:

* Track CPI time series
* Model CPI revisions
* Detect unstable macroeconomic indicators
* Block downstream analytics when revisions invalidate assumptions

Key characteristics:

* Revision‑aware ingestion
* Control‑plane driven promotion logic
* Gold models intentionally fail when macro conditions are unsafe

### 2. STOOQ – Equity Market Data

**Source:** STOOQ historical equities data

Purpose:

* Clean OHLCV market data
* Enforce strict market‑date grain
* Surface market anomalies
* Provide analytics‑ready equity aggregates

Key characteristics:

* Strong grain enforcement at silver layer
* Anomaly audit models in gold
* Trading‑calendar aware transformations

---

## Lakehouse Layers

### 1. Staging Layer

**Responsibility:** Ingestion correctness only

* Raw → typed, minimally cleaned data
* No business logic
* No assumptions about truth
* Views only (CI‑safe for Athena)

Staging answers only one question:

> *“Did we ingest what the source gave us, correctly?”*

---

### 2. Silver Layer

**Responsibility:** Business truth + structural integrity

This is where **data engineering discipline lives**.

Enforced rules:

* Canonical grain per domain
* Required identifiers present
* Structural correctness (no duplicates where forbidden)

**SEV‑1 violations block promotion immediately.**

Examples:

* STOOQ: duplicate (symbol, market_date) → **hard fail**
* FRED: missing identifiers or non‑numeric CPI values → **hard fail**

Silver models contain **explicit SQL promotion gates**, not just tests.

---

### 3. Gold Layer

**Responsibility:** Analytics‑ready, decision‑making data

* Business metrics
* Aggregations
* Audit and anomaly models
* Domain‑specific logic

Promotion rules:

* **SEV‑2 failures block gold** (business invalid)
* **SEV‑3 failures alert only** (monitoring)

Important: gold models are allowed to **fail by design** when upstream signals indicate unsafe conditions.

---

## Data Quality & Governance Model

This project uses a **severity‑based governance framework**, modeled after real production systems.

### Severity Levels

**SEV‑1 – Structural / Contract Violations**

* Grain violations
* Missing identifiers
* Invalid schema assumptions
* ❌ Blocks silver promotion

**SEV‑2 – Domain / Business Invalidity**

* CPI revisions invalidate regime analysis
* Impossible OHLC values
* ❌ Blocks gold promotion

**SEV‑3 – Anomalies / Monitoring**

* Outliers
* Zero volume days
* Data drift signals
* ⚠️ Alerts only

### Key Principle

Tests **detect**, gates **enforce**.

dbt tests surface problems.
SQL promotion gates decide whether data is allowed to move forward.

---

## Control‑Plane Pattern (FRED Domain)

The FRED CPI pipeline implements a **control‑plane architecture**:

1. `macro_cpi_diagnostics` evaluates revision stability
2. `macro_cpi_control_plane` emits ALLOW / BLOCK decisions
3. Gold CPI models read the control plane
4. Gold models **fail intentionally** when state = BLOCKING

This mirrors real financial systems where **data freshness does not equal data safety**.

---

## CI/CD & Automation

### GitHub Actions CI

Every pipeline run executes:

1. dbt compile
2. dbt run (layered)
3. dbt tests
4. Promotion gate enforcement

Failures are:

* Loud
* Deterministic
* Non‑recoverable without fixing root cause

No manual cleanup. No S3 wipes. No hacks.

### CI‑Safe Athena Patterns

* Staging models are **views** (avoid CTAS conflicts)
* Silver & gold are **tables**
* No destructive operations in CI

This reflects real‑world Athena constraints.

---

## Infrastructure as Code

All cloud resources are provisioned via **Terraform**:

* S3 buckets (raw / clean / gold / query results)
* IAM roles and policies
* Glue databases and permissions
* Lambda ingestion functions
* EventBridge schedules

Manual console setup is intentionally avoided.

---

## Project Philosophy

This project optimizes for **credibility**, not convenience.

What it intentionally shows:

* How pipelines fail
* How failures are contained
* How governance is enforced in code
* How analytics are blocked when trust is broken

What it intentionally avoids:

* Happy‑path only demos
* Notebook‑centric pipelines
* Silent data corruption
* Over‑reliance on tests without enforcement

---

## Who This Project Is For

* Hiring managers evaluating **Data Engineers**
* Teams assessing real‑world lakehouse design
* Engineers who care about correctness over cosmetics

If you are looking for a pretty dashboard demo, this is not it.

If you are looking for **how production data engineering actually works**, this is.

---

## Status

* Architecture: **Stable**
* Governance model: **Finalized**
* CI/CD: **Operational**
* Domains: **FRED & STOOQ production‑grade**
* Orchestration expansion: **Planned (Step Functions / MWAA if needed)**

---

## Disclaimer

This repository is a **portfolio‑grade system design artifact**.
It models patterns used in regulated, high‑trust data environments.

Some failures are intentional.
Some models are designed to block.

That is the point.
