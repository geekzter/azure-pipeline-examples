function Decode-JWT (
    [parameter(Mandatory=$true)]
    [string]
    $Token
) {
    if (!$Token) {
        return $null
    }
    try {
        $tokenParts = $Token.Split(".")

        Decode-JWTSegment $tokenParts[0] | Set-Variable tokenHeader
        Write-Debug "Token header:"
        $tokenHeader | Format-List | Out-String | Write-Debug
        Decode-JWTSegment $tokenParts[1] | Set-Variable tokenBody
        Write-Debug "Token body:"
        $tokenBody | Format-List | Out-String | Write-Debug

        return New-Object PSObject -Property @{
            Header = $tokenHeader
            Body = $tokenBody
        }
    } catch {
        Write-Warning "Failed to decode JWT token"
    }
}

function Decode-JWTSegment (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $TokenSegment
) {
    try {
        if (($TokenSegment.Length % 4) -ne 0) {
            $TokenSegment += ('=' * (4-($TokenSegment.Length % 4)))
        }
        [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($TokenSegment)) | Set-Variable tokenSegmentJson
        Write-Debug "Token segment JSON:"
        Write-JsonResponse $tokenSegmentJson
        $tokenSegmentJson | ConvertFrom-Json | Set-Variable tokenSegmentObject
        $tokenSegmentObject | Format-List | Out-String | Write-Debug
        return $tokenSegmentObject
    } catch {
        Write-Warning "Failed to decode JWT token segment"
        Write-Debug "Token segment: ${TokenSegment}"
    }
}

function Write-JsonResponse (
    [parameter(Mandatory=$true)]
    [ValidateNotNull()]
    $Json
) {
    if (Get-Command jq -ErrorAction SilentlyContinue) {
        $Json | jq -C | Write-Debug
    } else {
        Write-Debug $Json
    }
}