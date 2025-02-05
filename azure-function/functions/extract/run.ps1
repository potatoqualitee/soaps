using namespace System.Net

param(
    $Request,
    $TriggerMetadata
)

# Enable verbose and debug output
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'
$InformationPreference = 'Continue'

Write-Information "=== Starting document extraction ==="
Write-Information "Request method: $($Request.Method)"
Write-Information "Headers: $($Request.Headers | ConvertTo-Json)"

# Main execution flow
try {
    if (-not (Test-RequestValidation -Request $Request)) { return }

    $extractedContent = Import-RequestContent -Request $Request

    Send-OkResponse -Body @{
        status  = "success"
        message = "File(s) processed successfully"
        files   = $extractedContent
    }
} catch {
    Write-Error "Error processing request: $_"
    Send-InternalServerError -Message $_.Exception.Message
}