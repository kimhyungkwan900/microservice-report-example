param(
    [string]$Tag = "v2",
    [int]$Replicas = 2,
    [int]$LoadSeconds = 120,
    [switch]$NoHealthCheck
)

. "$PSScriptRoot\_encoding.ps1"
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$image = "pop2bubble/accommodation-reservation:$Tag"
$env:TAG = $Tag

Write-Host "==> 1) replica $Replicas 로 기동동" -ForegroundColor Cyan
if ($NoHealthCheck) {
    .\scripts\docker-local-up.ps1 -Replicas $Replicas -NoHealthCheck
} else {
    .\scripts\docker-local-up.ps1 -Replicas $Replicas
}

Start-Sleep -Seconds 10

Write-Host "`n==> 2) 부하 테스트 백그라운드 시작 (${LoadSeconds}s)" -ForegroundColor Cyan
$loadJob = Start-Job -FilePath "$projectRoot\scripts\docker-load-test.ps1" -ArgumentList @("http://localhost:8080/api/reservations", 50, $LoadSeconds)

Start-Sleep -Seconds 20

Write-Host "`n==> 3) 무정지 재배포 시뮬레이션션: $image" -ForegroundColor Cyan
docker compose up -d --no-deps --force-recreate accommodation-reservation

Write-Host "재배포 명령 실행 완료 부하 테스트 종료까지 대기..."
Wait-Job $loadJob | Out-Null
Receive-Job $loadJob
Remove-Job $loadJob

Write-Host ""
if ($NoHealthCheck) {
    Write-Host "대조군(No HealthCheck): Availability 하락 가능" -ForegroundColor Yellow
} else {
    Write-Host "실험군(HealthCheck): Availability 100%에 가깝게 유지" -ForegroundColor Green
}
