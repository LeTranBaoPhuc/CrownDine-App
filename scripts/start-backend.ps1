[CmdletBinding()]
param(
    [ValidateRange(1024, 65535)][int]$Port = 8081,
    [switch]$SkipBuild,
    [switch]$EnableMail,
    [switch]$EnableAI
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot 'backend'
$runtimeRoot = Join-Path $env:LOCALAPPDATA 'CrownDine\local-runtime'
$null = New-Item -ItemType Directory -Path $runtimeRoot -Force

if (!(Test-Path -LiteralPath (Join-Path $projectRoot '.env'))) {
    throw 'Missing .env. Configure local credentials using .env.example first.'
}

# Reuse a healthy instance; never terminate another application using this port.
$listener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
if ($listener) {
    try {
        $probe = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/layout/floors" -TimeoutSec 5
        if ($probe.status -eq 200 -and $null -ne $probe.data) {
            Write-Host "CrownDine backend is already running at http://127.0.0.1:$Port/api/"
            return
        }
    } catch { }
    throw "Port $Port is occupied by an unverified service. Choose another -Port."
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
if ($docker) {
    $containerState = & $docker.Source inspect --format '{{.State.Status}}' crowndine-dev-mysql 2>$null
    if ($LASTEXITCODE -eq 0 -and $containerState -ne 'running') {
        & $docker.Source start crowndine-dev-mysql | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Cannot start the CrownDine development database.' }
    }
}

$java = (Get-Command java -ErrorAction Stop).Source
if (!$SkipBuild) {
    $maven = (Get-Command mvn -ErrorAction Stop).Source
    Push-Location $backendRoot
    try {
        & $maven -Pdev '-DskipTests' package
        if ($LASTEXITCODE -ne 0) { throw 'Backend packaging failed.' }
    } finally { Pop-Location }
}

$builtJar = Get-ChildItem -LiteralPath (Join-Path $backendRoot 'target') -Filter '*.jar' |
    Where-Object { $_.Name -notmatch '(-sources|-javadoc)\.jar$' } |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (!$builtJar) { throw 'No backend JAR found. Run without -SkipBuild.' }

# Keep the running artifact outside target/: IDE/Maven clean and resource copies
# must not restart the server or remove the configuration from its classpath.
$runtimeJar = Join-Path $runtimeRoot "crowndine-$Port.jar"
Copy-Item -LiteralPath $builtJar.FullName -Destination $runtimeJar -Force
$stdout = Join-Path $runtimeRoot "backend-$Port.log"
$stderr = Join-Path $runtimeRoot "backend-$Port.error.log"
$javaArguments = @(
    '-Dspring.devtools.restart.enabled=false', '-jar', ('"{0}"' -f $runtimeJar),
    '--spring.profiles.active=dev', '--spring.devtools.restart.enabled=false',
    "--server.port=$Port", "--app.base-url=http://127.0.0.1:$Port"
)
if (!$EnableMail) {
    $javaArguments += @('--spring.mail.host=127.0.0.1', '--spring.mail.port=1',
        '--spring.mail.username=local@example.invalid', '--spring.mail.password=disabled-local',
        '--spring.mail.from=local@example.invalid', '--management.health.mail.enabled=false')
}
if (!$EnableAI) { $javaArguments += '--spring.ai.google.genai.api-key=disabled-local' }

$backendProcess = Start-Process -FilePath $java -ArgumentList $javaArguments `
    -WorkingDirectory $backendRoot -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr
Set-Content -LiteralPath (Join-Path $runtimeRoot "backend-$Port.pid") -Value $backendProcess.Id

$deadline = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $deadline) {
    $backendProcess.Refresh()
    if ($backendProcess.HasExited) { throw "Backend exited. Inspect $stdout and $stderr." }
    try {
        $probe = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/layout/floors" -TimeoutSec 2
        if ($probe.status -eq 200 -and $null -ne $probe.data) {
            Write-Host "Ready: http://127.0.0.1:$Port/api/ ($($probe.data.Count) floors)"
            Write-Host "PID: $($backendProcess.Id). Log: $stdout"
            if (!$EnableMail -or !$EnableAI) { Write-Host 'Mail/AI use local placeholders unless enabled explicitly.' }
            return
        }
    } catch { }
    Start-Sleep -Seconds 1
}
throw "Backend did not become ready. Inspect $stdout and $stderr."
