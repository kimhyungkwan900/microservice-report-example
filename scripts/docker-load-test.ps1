param(
    [string]$BaseUrl = "http://localhost:8080/api/reservations",
    [int]$Concurrency = 50,
    [int]$DurationSeconds = 120
)

. "$PSScriptRoot\_encoding.ps1"
$ErrorActionPreference = "SilentlyContinue"

$payload = @{
    roomId = 101
    userId = "loadtest"
    price = 120000
    checkInDate = "2026-06-10"
    checkOutDate = "2026-06-12"
} | ConvertTo-Json

Write-Host "==> 부하 테스트 시작" -ForegroundColor Cyan
Write-Host "URL=$BaseUrl, Concurrency=$Concurrency, Duration=${DurationSeconds}s"

$scriptBlock = {
    param($Url, $Body)
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Post -Body $Body -ContentType "application/json" -UseBasicParsing
        return [pscustomobject]@{ Success = $true; Status = [int]$response.StatusCode }
    } catch {
        $status = 0
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        }
        return [pscustomobject]@{ Success = $false; Status = $status }
    }
}

$jobs = @()
$endTime = (Get-Date).AddSeconds($DurationSeconds)
$total = 0
$success = 0

while ((Get-Date) -lt $endTime) {
    while ($jobs.Count -lt $Concurrency) {
        $jobs += Start-Job -ScriptBlock $scriptBlock -ArgumentList $BaseUrl, $payload
    }

    $finished = Wait-Job -Job $jobs -Any
    if ($finished) {
        $result = Receive-Job -Job $finished
        Remove-Job -Job $finished
        $jobs = $jobs | Where-Object { $_.Id -ne $finished.Id }
        $total++
        if ($result.Success -and ($result.Status -eq 201 -or $result.Status -eq 200)) {
            $success++
        }
    }
}

$jobs | Stop-Job -ErrorAction SilentlyContinue
$jobs | Remove-Job -ErrorAction SilentlyContinue

$availability = if ($total -gt 0) { [math]::Round(($success / $total) * 100, 2) } else { 0 }

Write-Host ""
Write-Host "==> 결과" -ForegroundColor Green
Write-Host "Transactions : $total"
Write-Host "Success      : $success"
Write-Host "Availability : $availability %"
Write-Host "Elapsed time : $DurationSeconds secs"
