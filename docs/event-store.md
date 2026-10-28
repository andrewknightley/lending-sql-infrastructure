# Agreement event store deployment

The companion lending-api event-sourcing change requires this schema. Publish/review this DACPAC first, explicitly import legacy agreements with all agreement writers stopped, then switch API versions. This repo owns database structure; the API never deploys the schema.

## New objects

- AgreementStream: CreditAgreementId primary key, unique AgreementNumber, Version bigint >= 1. A stream reserves the business number independently of its rebuildable projection.
- AgreementEvent: ordered (CreditAgreementId, StreamVersion) primary key, unique EventId, stable EventType, SchemaVersion, OccurredAtUtc and JSON Payload. StreamVersion starts at 1. Supported schema-v1 facts are AgreementCreated, AgreementActivated and AgreementImported.
- TR_AgreementEvent_Immutable: rejects UPDATE/DELETE of stored events with SQL error 51000. Ordinary rollback and whole disposable database removal remain possible. Administrators can disable triggers; this is not a tamper-evident audit system.

Events reference their stream, not CreditAgreement: deleting/rebuilding a projection cannot delete authoritative history. Stream-head changes, inserts and projection changes must share one transaction. Database constraints prevent duplicate positions/IDs/business numbers, invalid types/schema versions and non-JSON payloads. The API validates ordered contiguous streams and head consistency; SQL constraints alone do not make arbitrary SQL an event-store API. Use restricted runtime permissions and the API's transactional sessions.

## Cutover existing databases

1. Stop all agreement writers, including the old API, imports and seed jobs. Back up the intended database.
2. Generate and review the DACPAC deployment script using the existing Deploy.ps1 defaults, then explicitly publish the reviewed change. No existing tables/rows are dropped by this feature.
3. Run `scripts/Import.LegacyAgreements.sql` against the selected Lending database (for example in SSMS). It uses one transaction and imports only projection rows with no stream. Re-running it appends no duplicate baselines and changes no existing events or projection rowversions.
4. Verify every CreditAgreement has a stream and that each imported stream has one schema-v1 AgreementImported event. Run the API migration/replay tests before switching.
5. Start the companion event-sourced API and verify create/get/activate/repeat and stale ETags.

For our Docker development setup, from this repo in PowerShell:

```powershell
Get-Content -Raw scripts/Import.LegacyAgreements.sql | docker compose exec -T sqlserver sh -c 'SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -d Lending'
if ($LASTEXITCODE -ne 0) { throw 'Legacy agreement import failed.' }
```

The password is read from the existing container environment. This does not recreate/remove the container or volume. The script records accepted amount/rate/term, current status and original creation/activation timestamps, with a separate UTC import timestamp. It does not invent a historical creation/activation event series. It includes null fields and uses string enums/UTC ISO timestamps compatible with the API's schema-v1 deserializer.

Run optional seed/demo SQL BEFORE import. Direct SQL inserts after cutover are not event-sourced writes; they require an explicit baseline before use. Do not run the old API after switching: it would change only the projection and cause divergence. Roll back before cutover only; after event-sourced writes, recovery needs coordinated restore or roll-forward planning.

CreditAgreement retains its existing rowversion for HTTP ETag compatibility. Event-stream versions are a different concurrency mechanism. The API rebuild tool can regenerate a projection without altering events; this changes ETags and requires clients to reload. Stream reservations survive a missing projection. Replay may still require the referenced account/product rows for SQL foreign keys.

## Validation

SQL CI builds the DACPAC. Container CI publishes the actual DACPAC, seeds legacy rows, imports them twice, recreates the container with its volume retained and checks six tables, baseline uniqueness and persisted events. Companion API CI compares the new definitions/import script against this repo and tests real event replay, concurrency, rollback, rebuild and migration against SQL Server.

This slice does not add a broker/outbox, async projections, snapshots, cancellation/settlement workflows, customer/account event sourcing or a financial ledger. Those need separate designs. Event contract changes require schema-version/upcaster planning; never rewrite historical facts to fit a new CLR type.
