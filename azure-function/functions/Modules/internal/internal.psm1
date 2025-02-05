# Import all command files
Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | ForEach-Object { . $_.FullName }

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
    'Get-SectionFileBytes'

    # Schema generation and OpenAI integration
    'ConvertTo-OpenAISchema'
    'Get-OpenAIStructuredOutput'
    'Test-OpenAISchema'

    # HTTP response helpers
    'Send-OkResponse'
    'Send-BadRequest'
    'Send-InternalServerError'
    'Send-MethodNotAllowed'
    'Send-Unauthorized'
)