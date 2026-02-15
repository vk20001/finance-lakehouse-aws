# Lessons Learned

## Athena CTAS Behavior

Athena does not automatically clean temporary CTAS folders.
Explicit cleanup was required in CI.

---

## Lake Formation Permissions

Glue catalog permissions may be blocked by Lake Formation even if IAM allows access.

Proper principal mapping is critical.

---

## Event-Driven Transformation Anti-Pattern

Triggering GitHub Actions from AWS via repository_dispatch introduced unnecessary coupling and observability gaps.

The architecture was simplified to:

- Event-driven ingestion
- Scheduled transformations

This improved stability and clarity.

---

## Importance of Severity Gates

Natural SEV-2 events demonstrated that governance rules protect business data integrity.

A red pipeline can represent correct system behavior.
