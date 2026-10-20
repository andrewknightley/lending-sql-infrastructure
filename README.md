# Lending SQL infrastructure

Source-controlled SQL Server schema for a retail lending exercise. This repository owns the database schema and its deployment package. It does not yet provision a SQL Server instance or implement APIs, events, or microservices.

## What is included

| Location | Purpose |
| --- | --- |
| `src/Lending.Database/Lending.Database.sqlproj` | SDK-style SQL project targeting SQL Server 2022 (compatibility level 160) |
| `src/Lending.Database/Schemas/` | The `lending` schema |
| `src/Lending.Database/lending/Tables/` | Customer, Account, CreditProduct, and CreditAgreement definitions |
| `src/Lending.Database/lending/Indexes/` | Indexes supporting foreign-key lookups |
| `scripts/Build.ps1` | Validate SQL references and build the DACPAC |
| `scripts/Deploy.ps1` | Generate deployment SQL or publish the schema |
| `.github/workflows/ci.yml` | Build on all pushes and pull requests |
| `.github/workflows/deploy.yml` | Manually deploy or generate SQL from `main` |

## Domain model

A customer has many accounts. An account has many credit agreements. Each agreement references one credit product from the product catalogue. The agreement stores a snapshot of the accepted terms; later product changes do not change those terms automatically.

This version supports individual customers, GBP accounts, fixed loans, and revolving credit. `AgreedAmount` is the loan principal or revolving credit limit. An interest rate value of `7.5` means 7.5 percent annually, not APR. Repayments, balances, fees, joint customers, and a financial ledger are future work.

Primary keys identify records; unique constraints protect business numbers; foreign keys prevent orphaned records; check constraints validate amounts, statuses, and dates. No cascading deletes are configured. `rowversion` is a concurrency token, not a timestamp.

Cross-entity rules belong in the future domain layer: for example, whether a customer can open an account, whether a product is available, and whether an agreement type matches its product. These tables are not an event store. They can become read projections when event sourcing and CQRS are introduced.

## Prerequisites

- .NET 10 SDK. `global.json` allows installed stable .NET 10 feature bands.
- PowerShell 7 (`pwsh`), on Windows or Linux.
- Git for committing the repository.
- For deployment: a reachable SQL Server 2022 or later instance, and a login with deployment permissions. No database is needed just to build.

Microsoft.Build.Sql is pinned in the project; SqlPackage is pinned in the local tool manifest. NuGet access is required to restore them. Use the command line or VS Code's SQL Database Projects extension; Visual Studio support for SDK-style SQL projects depends on the installed version and extensions.

## Build locally

Open PowerShell 7 in the repository root:

```powershell
./scripts/Build.ps1
```

Or run the underlying command:

```powershell
dotnet build ./src/Lending.Database/Lending.Database.sqlproj --configuration Release
```

The output is `src/Lending.Database/bin/Release/Lending.Database.dacpac`. It contains the desired schema, not customer data. Build validates SQL syntax and object references; it does not prove a deployment will succeed against a particular database.

## Connect to a database

For Windows LocalDB, once LocalDB is installed, this is an example using Windows authentication:

```powershell
$env:LENDING_SQL_CONNECTION_STRING = 'Server=(localdb)\MSSQLLocalDB;Database=Lending;Integrated Security=True;Encrypt=True;TrustServerCertificate=True'
```

For a local SQL Server container or SQL Server Express using SQL authentication, set the same environment variable with the connection string appropriate to that instance. Include `Database=Lending`. Keep credentials out of source control. `TrustServerCertificate=True` is for a local instance with a self-signed certificate; use certificate validation for remote deployments.

SQL Server installation and container setup are the next exercise. The repository can be built before that setup is done.

## Generate deployment SQL

```powershell
./scripts/Deploy.ps1
```

The default action is `Script`. It builds the project, restores SqlPackage, connects to the target, compares schemas, and writes `artifacts/deployment.sql`. It does not apply the schema. It still needs a reachable server because the generated SQL depends on the target's existing state. SqlPackage may also create a companion master script when database creation requires it.

## Apply the schema

```powershell
./scripts/Deploy.ps1 -Action Publish
```

SqlPackage creates the target database if it does not exist and the login has permission to create databases. For an existing database, the publishing login needs `db_owner` permissions. Use a separate, less privileged login for future application code.

On subsequent deployments, SqlPackage compares the DACPAC with the target and generates the required changes. Re-running the same unchanged schema is supported. There is no numbered migration history in this approach.

The deployment options block changes identified as possible data loss, preserve objects absent from the project, and avoid scripting database option changes. This means deleting a table file does **not** automatically remove the existing database table. Data-loss detection is not a backup or a guarantee that every change is harmless. Review generated SQL when changing populated tables.

`Publish` recalculates the deployment against the current database; it does not execute a previously generated `deployment.sql`. Review again if the schema or target has changed. For renames or complex data transformations, plan an explicit migration rather than simply deleting and adding definitions.

## Check in to GitHub

Create an empty GitHub repository named `lending-sql-infrastructure`, without adding a README or .gitignore. Extract this starter folder and open a terminal inside it:

```powershell
git init -b main
git add .
git commit -m "Add lending SQL schema and deployment workflows"
git remote add origin https://github.com/YOUR-USERNAME/lending-sql-infrastructure.git
git push -u origin main
```

Replace `YOUR-USERNAME` with your GitHub username. Build outputs, deployment SQL, temporary files, and local credentials are ignored. The ZIP includes the `.github` and `.config` directories; retain them when extracting or copying files.

## GitHub Actions

### CI

Every push and pull request builds the SQL project and uploads the DACPAC named with the commit SHA. CI has no database credentials and does not deploy. This starter currently performs build validation, not database integration tests.

### Manual deployment

1. Create a GitHub environment named `development` under repository Settings > Environments.
2. Add an environment secret named `LENDING_SQL_CONNECTION_STRING` containing the target connection string, including the database name.
3. Ensure that the target server is reachable from the GitHub-hosted runner and that the deploying login has the necessary permissions.
4. Open Actions > Deploy SQL schema > Run workflow. Select `main`, then choose `Script` or `Publish`.

The workflow builds the selected `main` commit and serializes deployments to the development environment. `Script` uploads generated SQL as an artifact; `Publish` applies the schema. Runs against other branches are skipped. Optional GitHub environment protection rules can be configured separately if your team needs them.

A GitHub-hosted runner cannot reach SQL Server at `localhost` on your PC. Use the local deployment script for your local database. A future remote deployment can use a reachable server or an appropriately connected self-hosted runner; do not expose your local SQL Server publicly just for this exercise.

## Verify the deployed schema

Run this query in SSMS or a SQL editor connected to `Lending`:

```sql
SELECT s.name AS SchemaName, t.name AS TableName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE s.name = 'lending'
ORDER BY t.name;
```

Expected tables: Account, CreditAgreement, CreditProduct, Customer.

## Validation of this starter

The packaged files were checked for JSON, XML, and workflow structure, schema object/reference consistency, and archive contents. A .NET SDK, PowerShell, and SQL Server were not available in the creation environment, so the SQL project has **not** been compiled or deployed there. Run the build locally or through the included CI workflow before first deployment.

## References

- [Microsoft SQL database projects](https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/sql-database-projects)
- [Microsoft.Build.Sql tutorial](https://github.com/microsoft/DacFx/blob/main/src/Microsoft.Build.Sql/docs/Tutorial.md)
- [SqlPackage Publish](https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage-publish)
- [SqlPackage release notes](https://learn.microsoft.com/en-us/sql/tools/sqlpackage/release-notes-sqlpackage)
