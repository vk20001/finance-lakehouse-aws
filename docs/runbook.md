# Operational Runbook

## Daily Schedule

06:00 UTC – FRED ingestion  
06:05 UTC – STOOQ ingestion  
06:30 UTC – dbt transformation run  

---

## Normal Operation (Green CI)

If the GitHub Actions workflow completes successfully:

- Gold tables are updated.
- Data is considered valid.
- No action required.

---

## SEV-1 Failure (Structural Error)

Definition:
- Grain violations
- Null keys
- Schema mismatch

Behavior:
- Silver model fails.
- Gold is not executed.
- CI turns red.

Action:
- Investigate ingestion or schema issue.
- Fix and re-run.

---

## SEV-2 Failure (Business Validity Block)

Definition:
- CPI instability
- Broken market prices
- Business rule violations

Behavior:
- Gold promotion blocked.
- Previous gold remains intact.
- CI turns red.

Action:
- No immediate action required.
- Wait for next scheduled run.
- Escalate only if persists multiple days.

---

## Freshness Failure

Definition:
- Data not updated within expected window.

Behavior:
- CI warning or error depending on threshold.

Action:
- Verify ingestion.
- Confirm upstream availability.

---

## Escalation Guidelines

- Single-day SEV-2: Monitor.
- Multi-day SEV-2: Review business rule.
- SEV-1: Immediate investigation required.
