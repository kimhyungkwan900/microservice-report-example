param(
    [string]$DockerHubUsername = "pop2bubble",

    [string]$ImageName = "accommodation-reservation",
    [string]$Tag = "latest"
)

. "$PSScriptRoot\_encoding.ps1"
$ErrorActionPreference = "Stop"

$fullImage = "${DockerHubUsername}/${ImageName}:${Tag}"

Write-Host "==> Podman 이미지 빌드: $fullImage" -ForegroundColor Cyan
podman build -t $fullImage .

Write-Host "==> Docker Hub 로그인 (필요 시)" -ForegroundColor Cyan
podman login docker.io

Write-Host "==> Docker Hub Push: $fullImage" -ForegroundColor Cyan
podman push $fullImage

Write-Host "완료: $fullImage" -ForegroundColor Green
