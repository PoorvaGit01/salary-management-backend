# Design Notes

## Schema Decisions

The core domain table is `employees`, designed for high-volume listing and filtering while preserving data quality.

- Required identity and role fields: `first_name`, `last_name`, `job_title`.
- Compensation is stored as `salary decimal(14,2)` with `currency` (ISO-3), avoiding floating-point rounding issues.
- Geography is represented with `country` (ISO-2) for simple reporting and filtering.
- Optional but unique business identifiers (`email`, `employee_number`) use partial unique indexes so multiple `NULL` values remain valid.
- `employment_status` is stored as an enum-backed integer for compact storage and controlled state transitions.
- Indexes target expected query paths:
  - `country`
  - `country, job_title`
  - unique partial indexes on `email` and `employee_number`

This schema balances strictness (for correctness) and flexibility (for incomplete optional data during onboarding imports).

## Why PostgreSQL over SQLite

PostgreSQL was chosen because the project behavior and scale are closer to production-style workloads than local-only prototyping:

- Better concurrency model for multi-request API usage and concurrent writes.
- Strong support for partial indexes, which are used for nullable-but-unique fields.
- More realistic parity with typical production deployment stacks.
- Better long-term headroom for analytics, query tuning, and future relational complexity.

SQLite is excellent for very small/local apps, but PostgreSQL provides stronger guarantees and operational behavior for this API-first employee system.

## Seeding Approach

Seeding is intentionally optimized for repeatability and speed in development:

- Seed data creates a large synthetic employee dataset (10,000 rows) for realistic pagination/filtering behavior.
- Seeds draw first/last names from curated text sources, then generate other fields programmatically.
- Inserts are batched with `insert_all!` after a full-table replace to keep reseeding fast.
- Optional deterministic runs are supported via `SEED_RANDOM=<int>` to reproduce data patterns.
- Bulk replacement is guarded to avoid destructive behavior in production.

This approach keeps local environments easy to reset while still exercising realistic data volumes.

## AI Tooling Note

AI tools were used as coding assistants for refactoring and documentation tasks:

- Splitting a large UI module into testable units (`EmployeeTable`, `EmployeeFormDialog`, `DeleteConfirmDialog`, `useEmployees`).
- Verifying wiring consistency and catching integration regressions during extraction.
- Drafting and polishing this design summary from existing repository artifacts.

All generated output was reviewed and adjusted to match project conventions and runtime behavior.
