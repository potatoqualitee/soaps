# OpenAI API integration functions
function Get-OpenAIStructuredOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Content,

        [Parameter(Mandatory)]
        [string]$Schema,

        [Parameter()]
        [string]$Instructions,

        [Parameter()]
        [string]$Model = $env:Model ?? "gpt-4o"
    )

    begin {
        Write-Information "=== Starting OpenAI structured output extraction ==="
        Write-Information "Initializing OpenAI structured output extraction"

        # Verify environment variables
        Write-Information "Checking API credentials..."
        if (-not $env:API_KEY) {
            Write-Error "Neither OpenAI, GitHub or Azure OpenAI credentials found in environment variables"
            throw "Neither OpenAI, GitHub or OpenAI credentials found in environment variables"
        }
        Write-Information "API credentials verified successfully"

        # Default instructions if none provided
        $defaultInstructions = "You are an AI assistant that extracts structured information from documents. Your task is to analyze the provided text and extract relevant information according to the provided schema. Be precise and thorough in your extraction."

        Write-Information "Using $(if ($Instructions) { 'custom' } else { 'default' }) instructions"
        Write-Information "Extraction parameters configured"
    }

    process {
        try {
            Write-Information "Processing content length: $($Content.Length) characters"
            Write-Information "Preparing API request parameters"
            # Set up API parameters
            $apiParams = @{
                Model         = $Model
                SystemMessage = $Instructions ?? $defaultInstructions
                Message       = $Content
                Format        = "json_schema"
                JsonSchema    = $Schema
            }

            # Add provider-specific parameters
            if ($env:API_BASE -match "azure" -or $env:API_BASE -match "github") {
                $apiParams['ApiKey'] = $env:API_KEY
                $apiParams['ApiBase'] = $env:API_BASE
                $apiParams['ApiType'] = 'Azure'

                Write-Information "Azure API endpoint configured: $env:API_BASE"
            } else {
                Write-Information "Using OpenAI API"
                $apiParams['ApiKey'] = $env:API_KEY
                $apiParams['ApiType'] = 'OpenAI'
                Write-Information "Using standard OpenAI endpoint"
            }

            # Initialize PSOpenAI context before each API call since global state is lost between function executions
            Write-Information "Initializing PSOpenAI context..."
            $splat = @{
                ApiKey      = $apiParams.ApiKey
                ApiType     = $apiParams.ApiType
                ApiBase     = $apiParams.ApiBase
                ErrorAction = 'Stop'
            }
            $null = Set-OpenAIContext @splat

            # Make the API call
            Write-Debug "Requesting completion with parameters: $($apiParams | ConvertTo-Json -Depth 20)"
            Write-Information "Sending request to OpenAI API..."

            # Convert schema string to object for property count
            $schemaObj = $Schema | ConvertFrom-Json
            Write-Information "Making API call with $($schemaObj.schema.properties.Count) schema properties to extract"

            $result = Request-ChatCompletion @apiParams -Verbose
            Write-Information "Response received from OpenAI API"
            Write-Information "Processing API response"

            # Return the structured output
            if ($result.Answer) {
                Write-Information "Successfully extracted structured data"
                Write-Information "Converting JSON response to PowerShell object"
                $parsed = $result.Answer | ConvertFrom-Json
                Write-Information "=== OpenAI extraction completed successfully ==="
                return $parsed
            } else {
                Write-Error "No response received from OpenAI"
                throw "No response received from OpenAI"
            }
        } catch {
            Write-Error "Error getting structured output from OpenAI: $_"
            Write-Information "=== OpenAI extraction failed ==="
            throw
        }
    }
}