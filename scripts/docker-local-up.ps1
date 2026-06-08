param(
    [int]$Replicas = 1,
    [switch]$NoHealthCheck,
    [switch]$Pull
)

. "$PSScriptRoot\_encoding.ps1"
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$composeArgs = @("compose", "up", "-d", "--build", "--remove-orphans", "--scale", "accommodation-reservation=$Replicas")
if ($NoHealthCheck) {
    $composeArgs += @("-f", "docker-compose.yml", "-f", "docker-compose.no-healthcheck.yml")
}
if ($Pull) {
    $composeArgs += "--pull", "always"
}

Write-Host "==> Docker Compose 기동 (replicas=$Replicas)" -ForegroundColor Cyan
docker @composeArgs

Write-Host ""
Write-Host "접속 URL" -ForegroundColor Green
Write-Host "  웹 UI : http://localhost:8080"
Write-Host "  API   : http://localhost:8080/api/reservations"
Write-Host ""
Write-Host "상태 확인:" -ForegroundColor Yellow
Write-Host "  docker compose ps"
Write-Host "  docker compose logs -f accommodation-reservation"
