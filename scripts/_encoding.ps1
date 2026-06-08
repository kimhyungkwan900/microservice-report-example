# Windows PowerShell 콘솔 한글 출력용 UTF-8 설정
if ($Host.Name -eq 'ConsoleHost') {
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    } catch {
        # 일부 호스트에서는 무시
    }
}
$OutputEncoding = [System.Text.Encoding]::UTF8
