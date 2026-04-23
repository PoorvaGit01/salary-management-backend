# Salary Management Backend

Rails 8 API and web application using **PostgreSQL** for data storage.

## Live Links

- Frontend: https://salary-management-frontend.vercel.app/
- Backend API: https://salary-management-backend-fxer.onrender.com/api/v1/employees
- Loom Demo: https://www.loom.com/share/1126c3fe3a7a42d485a8e55df9815807

## Requirements

- Ruby (see [`.ruby-version`](.ruby-version))
- [Bundler](https://bundler.io/)
- PostgreSQL 14+ (local install, Docker, or a managed service)

## Configuration (`.env`)

The app reads database settings from your environment. In **development** and **test**, variables from a **`.env`** file in the project root are loaded automatically via [dotenv-rails](https://github.com/bkeepers/dotenv).

1. Copy the example file and edit values for your machine:

   ```bash
   cp .env.example .env
   ```

2. Set PostgreSQL connection variables (when not using `DATABASE_URL`):

   | Variable | Description | Default (in `config/database.yml`) |
   |----------|-------------|-------------------------------------|
   | `PGHOST` | Server host | `localhost` |
   | `PGPORT` | Server port | `5432` |
   | `PGUSER` | Username | Your OS login (`USER`), or `postgres` if neither is set |
   | `PGPASSWORD` | Password | *(empty)* |
   | `DATABASE_NAME` | Development database name | `salary_management_backend_development` |
   | `DATABASE_TEST_NAME` | Test database name | `salary_management_backend_test` |

3. Optional: set **`DATABASE_URL`** (e.g. `postgres://user:pass@host:5432/dbname`) to connect with a single URL for **development** or **test** primary database. If `DATABASE_URL` is set, it takes precedence over `PG*` for that environment’s main config block.

4. **Production** uses the same `PG*` variables for Solid Cache, Solid Queue, and Solid Cable databases. The **primary** database can be set with **`DATABASE_URL`** or with **`DATABASE_NAME`** plus `PG*`. Additional production database names default to:

   - `salary_management_backend_production_cache`
   - `salary_management_backend_production_queue`
   - `salary_management_backend_production_cable`

   Override with `DATABASE_CACHE_NAME`, `DATABASE_QUEUE_NAME`, and `DATABASE_CABLE_NAME` if needed.

`.env` is listed in `.gitignore`; only [`.env.example`](.env.example) is committed as a template.

## Database setup

Ensure PostgreSQL is running and your `.env` (or shell environment) matches your server.

Create databases, run migrations, and seed (if applicable):

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

Or use the setup script (installs gems, prepares the DB, starts the dev server):

```bash
bin/setup
```

Run the test suite after preparing the test database:

```bash
RAILS_ENV=test bin/rails db:test:prepare test
```

## Database seeding

The default seed loads **10,000 synthetic employees** for local development and load testing.

- **Names** — Each row’s first and last name are chosen **independently** by sampling from [`db/data/first_names.txt`](db/data/first_names.txt) and [`db/data/last_names.txt`](db/data/last_names.txt).
- **Performance** — Seeds use **`insert_all!` in batches** (2,000 rows per insert) after a single `DELETE`, so engineers can re-run `db:seed` often without waiting on per-record creates or validations.
- **Reproducible randomness** — Optional: set `SEED_RANDOM` to a fixed integer so job titles, departments, salaries, and name draws repeat across runs:

  ```bash
  SEED_RANDOM=42 bin/rails db:seed
  ```

- **Production** — `EmployeesBulkSeed` **does not run in `RAILS_ENV=production`**. It would replace every employee row, so it is skipped there with a warning.

Implementation lives in [`db/seeds/employees_bulk_seed.rb`](db/seeds/employees_bulk_seed.rb) and is invoked from [`db/seeds.rb`](db/seeds.rb).

## Other topics

* **Design decisions** — see [`DESIGN.md`](DESIGN.md) for schema rationale, database choice, seeding strategy, and AI tooling notes
* **Ruby version** — see `.ruby-version`
* **How to run the test suite** — `bin/rails test` (and `bin/rails test:system` for system tests)
* **Deployment** — see [Kamal](https://kamal-deploy.org/) config in `config/deploy.yml` and container build in `Dockerfile`
