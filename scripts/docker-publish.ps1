param(
    [string]$DockerHubUsername = "pop2bubble",
    [string]$ImageName = "accommodation-reservation",
    [string]$Tag = "latest",
    [switch]$SkipPush
)

. "$PSScriptRoot\_encoding.ps1"
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$fullImage = "${DockerHubUsername}/${ImageName}:${Tag}"

Write-Host "==> Docker build: $fullImage" -ForegroundColor Cyan
docker build -t $fullImage .

if ($SkipPush) {
    Write-Host "완료 (push 생략략): $fullImage" -ForegroundColor Green
    exit 0
}

Write-Host "==> Docker Hub login" -ForegroundColor Cyan
docker login docker.io -u $DockerHubUsername

Write-Host "==> Docker push: $fullImage" -ForegroundColor Cyan
docker push $fullImage

Write-Host "완료: $fullImage" -ForegroundColor Green
