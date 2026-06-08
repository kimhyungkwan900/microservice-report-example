param(
    [string]$BaseUrl = "http://localhost:8080"
)

. "$PSScriptRoot\_encoding.ps1"
. "$PSScriptRoot\_api.ps1"
$ErrorActionPreference = "Stop"

function Invoke-ApiErrorMessage {
    param($ErrorRecord)
    if ($ErrorRecord.Exception.Response) {
        $stream = $ErrorRecord.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        return $reader.ReadToEnd()
    }
    return $ErrorRecord.Exception.Message
}

Write-Host "==> API 게이트웨이 라우팅 테스트 ($BaseUrl)" -ForegroundColor Cyan

Write-Host "`n[1] GET /api/rooms"
$rooms = Invoke-Utf8Api -Uri "$BaseUrl/api/rooms" -Method Get
Write-Utf8Json $rooms

$availableRoom = $rooms | Where-Object { $_.stockCount -gt 0 } | Select-Object -First 1
if (-not $availableRoom) {
    throw "예약 가능한 객실이 없습니다.. (모든 객실 수 = 0) docker compose restart 로 H2 데이터를 초기화하거나 다른 roomId를 사용하세요."
}

Write-Host "`n[2] POST /api/reservations (roomId=$($availableRoom.roomId), stock=$($availableRoom.stockCount))"
$body = @{
    roomId = $availableRoom.roomId
    userId = "customer01"
    price = 120000
    checkInDate = "2026-06-10"
    checkOutDate = "2026-06-12"
} | ConvertTo-Json -Compress

try {
    $reservation = Invoke-Utf8Api -Uri "$BaseUrl/api/reservations" -Method Post -Body $body
} catch {
    $detail = Invoke-ApiErrorMessage $_
    throw "예약생성 실패패 (HTTP 400): $detail`nroomId=$($availableRoom.roomId) 재고=$($availableRoom.stockCount)"
}
Write-Utf8Json $reservation

Write-Host "`n[3] POST /api/reservations/$($reservation.id)/pay"
$paid = Invoke-Utf8Api -Uri "$BaseUrl/api/reservations/$($reservation.id)/pay" -Method Post
Write-Utf8Json $paid

Write-Host "`n[4] GET /api/payments"
$payments = Invoke-Utf8Api -Uri "$BaseUrl/api/payments" -Method Get
Write-Utf8Json $payments

Write-Host "`nAPI TEST COMPLETED" -ForegroundColor Green
