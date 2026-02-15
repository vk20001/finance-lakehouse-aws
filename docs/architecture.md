# Architecture Overview

## System Summary

This project implements a production-grade finance lakehouse on AWS using:

- Event-driven ingestion (EventBridge + Lambda)
- S3 for storage (raw / clean / gold layers)
- AWS Glue Data Catalog
- Amazon Athena for query execution
- dbt for transformation and governance
- GitHub Actions for scheduled transformation runs

The system follows a medallion-style layering:

raw → staging → silver → gold

Ingestion and transformation are intentionally decoupled to ensure deterministic and auditable data operations.

---

## Ingestion Layer (AWS)

### Flow
EventBridge → Lambda → S3 raw → Glue Catalog

- FRED ingestion runs at 06:00 UTC
- STOOQ ingestion runs at 06:05 UTC
- Data lands in the `raw` bucket
- Glue metadata is updated automatically

The ingestion layer does not perform transformations.

---

## Transformation Layer (dbt + Athena)

### Execution Model
Transformations are scheduled daily at 06:30 UTC via GitHub Actions.

This buffer ensures ingestion completes before transformations begin.

### Layer Responsibilities

**Staging**
- Light typing and normalization
- No business logic

**Silver**
- Grain enforcement
- Structural validation
- SEV-1 quality gates

**Gold**
- Business-level transformations
- Domain-level validity rules
- SEV-2 promotion gates

Gold tables are protected and only updated when business rules pass.

---

## Automation Philosophy

- Ingestion is event-driven.
- Transformations are schedule-driven.
- Quality gates control promotion.
- No cross-system triggers are used.

This ensures observability, reproducibility, and operational stability.
