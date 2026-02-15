# Data Quality & Governance

The pipeline enforces a severity-based promotion model.

---

## SEV-1: Structural Violations

Enforced at the silver layer.

Examples:
- Duplicate primary keys
- Null identifiers
- Grain violations

Effect:
- Blocks silver.
- Stops downstream models.
- Fails CI.

---

## SEV-2: Business Validity Violations

Enforced at the gold layer.

Examples:
- CPI revision instability
- Invalid OHLC relationships
- Market anomalies beyond tolerance

Effect:
- Blocks gold promotion.
- Preserves last valid gold.
- Fails CI.

---

## SEV-3: Informational Anomalies

Examples:
- Outlier volumes
- Statistical irregularities

Effect:
- Logged but does not block.

---

## Governance Philosophy

The system prioritizes correctness over availability.

Bad data is never promoted to gold.
