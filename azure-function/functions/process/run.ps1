using namespace System.Net

param(
    $Request,
    $TriggerMetadata
)

# Enable verbose and debug output
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'
$InformationPreference = 'Continue'

Write-Information "=== Starting document processing pipeline ==="
Write-Information "Request method: $($Request.Method)"
Write-Information "Headers: $($Request.Headers | ConvertTo-Json)"

# Main execution flow
try {
    if (-not (Test-RequestValidation -Request $Request)) { return }

    # Get metadata and instructions from headers
    $fileMetadata = Get-HeaderValue -Headers $Request.Headers -Name 'x-file-metadata'
    $openAIInstructions = Get-HeaderValue -Headers $Request.Headers -Name 'x-openai-instructions'
    $customSchema = Get-HeaderValue -Headers $Request.Headers -Name 'x-custom-schema'
    $aiModel = Get-HeaderValue -Headers $Request.Headers -Name 'x-openai-model'

    # Check for either metadata or custom schema
    if (-not ($fileMetadata -or $customSchema)) {
        Write-Warning "No schema source provided"
        Send-BadRequest -Message "Either x-file-metadata or x-custom-schema header is required"
        return
    }

    # First step: Extract document content
    $extractedContent = Import-RequestContent -Request $Request

    # Second step: Generate or use provided OpenAI schema
    Write-Information "Determining schema source"
    $schema = if ($customSchema) {
        # Parse and validate custom schema
        try {
            $parsedSchema = $customSchema #| ConvertFrom-Json -Depth 20
            if (-not (Test-OpenAISchema -Schema $parsedSchema)) {
                throw "Invalid schema format: $parsedSchema"
            }
            $parsedSchema
        } catch {
            Write-Warning "Invalid custom schema: $_"
            Send-BadRequest -Message "Invalid custom schema format"
            return
        }
    } else {
        # Generate schema from metadata
        Write-Information "Generating OpenAI schema from metadata"
        $generatedSchema = ConvertTo-OpenAISchema -MetadataJson $fileMetadata
        if (-not (Test-OpenAISchema -Schema $generatedSchema)) {
            Write-Warning "Invalid schema generated from metadata"
            Send-BadRequest -Message "Invalid metadata schema"
            return
        }
        $generatedSchema
    }

    # Third step: Process each document with OpenAI
    $results = @()
    foreach ($document in $extractedContent) {
        Write-Information "Processing document: $($document.fileName)"

        # Get structured output from OpenAI
        $openAIParams = @{
            Content      = $document.content
            Schema       = $schema
            Instructions = $openAIInstructions
        }
        if ($aiModel) {
            Write-Information "Using custom AI model from header: $aiModel"
            $openAIParams['Model'] = $aiModel
        }
        $structuredData = Get-OpenAIStructuredOutput @openAIParams

        $results += @{
            fileName = $document.fileName
            data     = $structuredData
        }
    }

    # Return combined results
    Send-OkResponse -Body @{
        status  = "success"
        message = "Documents processed successfully"
        results = $results
    }
} catch {
    Write-Error "Error processing request: $_"
    Send-InternalServerError -Message $_.Exception.Message
}
