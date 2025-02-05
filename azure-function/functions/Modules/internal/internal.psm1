# Import functions from individual files
. $PSScriptRoot/Document-Content.ps1
. $PSScriptRoot/Request-Processing.ps1
. $PSScriptRoot/Schema-Generation.ps1
. $PSScriptRoot/OpenAI-Integration.ps1
. $PSScriptRoot/Send-HttpResponse.ps1

# Export functions for module use
Export-ModuleMember -Function @(
    # Document processing
    'Get-DocumentContent'
    'Export-DocumentContent'
    'Expand-OfficeContent'
    'Expand-PdfContent'
    'Expand-BinaryContent'
    'Import-RequestContent'
    'Invoke-DocProcessing'

    # Request processing
    'Test-RequestValidation'
    'Get-MultipartContent'
    'Get-FileContent'
    'Get-HeaderValue'

    # Schema generation and OpenAI integration
    'ConvertTo-OpenAISchema'
    'Get-OpenAIStructuredOutput'
    'Test-OpenAISchema'

    # HTTP response helpers
    'Send-OkResponse'
    'Send-BadRequest'
    'Send-InternalServerError'
)