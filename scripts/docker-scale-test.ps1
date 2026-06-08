param(
    [int]$Replicas = 3
)

. "$PSScriptRoot\_encoding.ps1"
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "==> 수동 스케일 아웃웃 (HPA 대체 체험): replicas=$Replicas" -ForegroundColor Cyan
docker compose up -d --scale accommodation-reservation=$Replicas

Start-Sleep -Seconds 15
Write-Host "`n컨테이너 목록록:"
docker compose ps accommodation-reservation

Write-Host "`nCPU/메모리 모니터링 Ctrl+C 종료):"
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
