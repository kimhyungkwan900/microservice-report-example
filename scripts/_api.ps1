function Get-Utf8ResponseText {
    param($WebResponse)

    if ($null -ne $WebResponse.RawContentStream) {
        $ms = New-Object System.IO.MemoryStream
        $WebResponse.RawContentStream.Position = 0
        $WebResponse.RawContentStream.CopyTo($ms)
        return [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
    }

    if ($WebResponse.Content -is [byte[]]) {
        return [System.Text.Encoding]::UTF8.GetString($WebResponse.Content)
    }

    return [string]$WebResponse.Content
}

function Invoke-Utf8Api {
    param(
        [string]$Uri,
        [ValidateSet('Get', 'Post', 'Put', 'Patch', 'Delete')]
        [string]$Method = 'Get',
        [string]$Body,
        [string]$ContentType = 'application/json; charset=utf-8'
    )

    $params = @{
        Uri             = $Uri
        Method          = $Method
        UseBasicParsing = $true
    }

    if ($Body) {
        $params.Body = [System.Text.Encoding]::UTF8.GetBytes($Body)
        $params.ContentType = $ContentType
    }

    $response = Invoke-WebRequest @params
    $text = Get-Utf8ResponseText $response

    if ($text.StartsWith('{') -or $text.StartsWith('[')) {
        return $text | ConvertFrom-Json
    }

    return $text
}

function Write-Utf8Json {
    param(
        $InputObject,
        [int]$Depth = 5
    )

    $json = $InputObject | ConvertTo-Json -Depth $Depth
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json + [Environment]::NewLine)
    $stdout = [Console]::OpenStandardOutput()
    $stdout.Write($bytes, 0, $bytes.Length)
}
