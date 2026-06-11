param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$CheckIn = (Get-Date).ToString("yyyy-MM-dd"),
    [string]$CheckOut = (Get-Date).AddDays(2).ToString("yyyy-MM-dd")
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

Write-Host "==> API 게이트웨이 라우트 테스트 ($BaseUrl)" -ForegroundColor Cyan

# [1] GET /api/rooms
Write-Host "`n[1] GET /api/rooms?checkInDate=$CheckIn&checkOutDate=$CheckOut"
$rooms = Invoke-Utf8Api -Uri "$BaseUrl/api/rooms?checkInDate=$CheckIn&checkOutDate=$CheckOut" -Method Get
Write-Utf8Json $rooms

$availableRoom = $rooms | Where-Object { $_.stockCount -gt 0 } | Select-Object -First 1
if (-not $availableRoom) {
    throw "예약 가능한 객실이 없습니다... (모든 객실 수 = 0) docker compose restart 로 H2 데이터를 초기화하거나 다른 roomId를 사용하세요."
}

# [2] POST /api/reservations 
Write-Host "`n[2] POST /api/reservations (roomId=$($availableRoom.roomId), stock=$($availableRoom.stockCount))"


$totalPrice = 120000 
if ($availableRoom.pricePerNight) {
    $duration = (([datetime]$CheckOut) - ([datetime]$CheckIn)).Days
    $totalPrice = $availableRoom.pricePerNight * $duration
}

$body = @{
    roomId      = $availableRoom.roomId
    userId      = "customer01"
    price       = $totalPrice
    checkInDate = $CheckIn
    checkOutDate = $CheckOut
} | ConvertTo-Json -Compress

try {
    $reservation = Invoke-Utf8Api -Uri "$BaseUrl/api/reservations" -Method Post -Body $body
} catch {
    $detail = Invoke-ApiErrorMessage $_
    throw "예약생성 실패 (HTTP 400): $detail`nroomId=$($availableRoom.roomId) 재고=$($availableRoom.stockCount)"
}
Write-Utf8Json $reservation

# [3] POST /api/reservations/{id}/pay
Write-Host "`n[3] POST /api/reservations/$($reservation.id)/pay"
$paid = Invoke-Utf8Api -Uri "$BaseUrl/api/reservations/$($reservation.id)/pay" -Method Post
Write-Utf8Json $paid

# [4] GET /api/payments
# 특정 예약에 파생된 결제 조회가 가능하도록 쿼리 파라미터 구조 확장 대비 (필요시 호출 형태 정합성 유지)
Write-Host "`n[4] GET /api/payments"
$payments = Invoke-Utf8Api -Uri "$BaseUrl/api/payments" -Method Get
Write-Utf8Json $payments

Write-Host "`nAPI TEST COMPLETED" -ForegroundColor Green