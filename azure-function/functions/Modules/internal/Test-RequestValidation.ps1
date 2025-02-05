using namespace System.Net

function Test-RequestValidation {
    param (
        [Parameter(Mandatory)]
        [object]$Request
    )

    if (-not $Request.Body) {
        Write-Warning "Request validation failed: No content in request body"
        Send-BadRequest -Message "No content found in request"
        return $false
    }

    return $true
}