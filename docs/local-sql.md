# Local SQL Server with Docker Compose

Run these commands from the lending-sql-infrastructure repository root in PowerShell 7. Use Docker Desktop with Linux containers and an x64 machine; allocate at least 2 GB of memory to Docker. The server uses SQL Server 2022 Developer edition for development and testing.

## Start SQL Server

Set a local password with at least 8 characters, using at least three of uppercase letters, lowercase letters, digits and symbols:

```powershell
$env:MSSQL_SA_PASSWORD = Read-Host 'Choose a local SQL sa password' -MaskInput
docker compose up -d --wait --wait-timeout 240
docker compose ps
```

Keep this PowerShell session open for deployment. Alternatively, copy `.env.example` to `.env` and fill in the password there (single-quote the value if it contains a dollar sign or hash). The shell variable takes precedence over `.env`. Never commit the filled-in file; it is ignored.

The host endpoint is `localhost,14330`, bound only to your machine's loopback interface to avoid conflicting with SQLExpress. Inside the container SQL Server still listens on 1433. The health check waits until SQL accepts queries. Starting the server does not deploy the Lending schema or copy your SQLExpress data.

## Deploy the schema

If using only a `.env` file, first set `$env:MSSQL_SA_PASSWORD` with the same password using the prompt above. Construct the connection string with a quoted password so punctuation is handled correctly:

```powershell
$sqlPassword = $env:MSSQL_SA_PASSWORD.Replace('"', '""')
$env:LENDING_SQL_CONNECTION_STRING = "Server=localhost,14330;Database=Lending;User ID=sa;Password=""$sqlPassword"";Encrypt=True;TrustServerCertificate=True"
./scripts/Deploy.ps1
# Review artifacts/deployment.sql, then apply:
./scripts/Deploy.ps1 -Action Publish
```

The existing deployment script builds the DACPAC and creates `Lending` if necessary. SQL authentication is used because this Linux container does not use your Windows integrated identity. The certificate exception is for this local development server.

Optionally load the existing development seed script after publishing:

```powershell
Get-Content -Raw ./scripts/Seed.Development.sql | docker compose exec -T sqlserver sh -c 'SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -d Lending'
```

SSMS connection settings: server `localhost,14330`, SQL Server Authentication, login `sa`, your local password, and Trust Server Certificate enabled.

## Connect the Lending API

In the same PowerShell session, retain the deployment connection string, then change to the sibling API repository:

```powershell
cd ../lending-api
$env:ConnectionStrings__Lending = $env:LENDING_SQL_CONNECTION_STRING
dotnet run --project src/Lending.Api
```

The environment setting overrides the API connection string, including any SQLExpress value in user secrets. Visit `http://localhost:5080/health/ready` and try the requests in `Lending.Api.http`. For a fresh shell, reconstruct the connection string above first. The API remains a host process; this Compose file runs the database.

Using `sa` here is a local development convenience; use a separate login with appropriate permissions in hosted environments.

## Stop, restart and preserve data

Return to the infrastructure repository before running Compose commands.

```powershell
docker compose stop
docker compose start --wait
# Or remove containers and the Compose network, retaining database files:
docker compose down
docker compose up -d --wait --wait-timeout 240
```

A named volume mounted at `/var/opt/mssql` retains database files even when containers are removed and recreated. Keep the same Compose project name (`lending-local`) to reuse it. A volume is persistence, not a backup.

**Destructive reset:** `docker compose down --volumes` deletes this project's database volume and all its data. Use it only when you deliberately want a fresh database; then start again, publish and seed. Changing the password variable does not change the `sa` password already stored in an existing volume. Keep the original password, change it through SQL, or deliberately reset a disposable database.

If startup fails, inspect `docker compose logs --tail 100 sqlserver`. Check Docker is running in Linux mode, password complexity, memory allocation, and whether port 14330 is free. Do not paste resolved Compose configuration publicly because it contains the password.

## Automated validation

`.github/workflows/local-sql.yml` starts this Compose service on a disposable GitHub runner, publishes the real DACPAC, loads seed data, removes/recreates the container, then verifies the tables and seed records survive. Its final cleanup deletes only the runner's disposable volume.

References: [SQL Server container configuration](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-docker-container-configure), [Compose interpolation](https://docs.docker.com/reference/compose-file/interpolation).
