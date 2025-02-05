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
        [string]$Model = $env:Model ?? "gpt-4o-mini"
    )

    begin {
        Write-Information "=== Starting OpenAI structured output extraction ==="
        Write-Information "Initializing OpenAI structured output extraction"

        # Verify environment variables
        Write-Information "Checking API credentials..."
        if (-not $env:OPENAI_API_KEY) {
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
            if ($env:OPENAI_API_BASE -match "azure" -or $env:OPENAI_API_BASE -match "github") {
                $apiParams['ApiKey'] = $env:OPENAI_API_KEY
                $apiParams['ApiBase'] = $env:OPENAI_API_BASE
                $apiParams['ApiType'] = 'Azure'

                Write-Information "Azure API endpoint configured: $env:OPENAI_API_BASE"
            } else {
                Write-Information "Using OpenAI API"
                $apiParams['ApiKey'] = $env:OPENAI_API_KEY
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
            $ull = Set-OpenAIContext @splat

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

# Helper function to validate schema before sending to OpenAI
function Test-OpenAISchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Schema
    )

    Write-Information "=== Starting schema validation ==="
    Write-Information "Beginning OpenAI schema validation"

    try {
        # Convert schema string to object
        $schemaObj = $Schema | ConvertFrom-Json

        # Required schema properties
        $requiredProps = @('name', 'strict', 'schema')
        Write-Information "Checking required schema properties: $($requiredProps -join ', ')"

        Write-Information "Validating schema structure"
        $missingProps = $requiredProps | Where-Object { -not $schemaObj.$_ }

        if ($missingProps) {
            Write-Error "Schema validation failed: Missing required properties"
            Write-Information "Missing properties: $($missingProps -join ', ')"
            throw "Invalid schema: Missing required properties: $($missingProps -join ', ')"
        }
        Write-Information "All required properties present"

        # Schema must have type 'object'
        Write-Information "Checking schema type"
        if ($schemaObj.schema.type -ne 'object') {
            Write-Error "Schema validation failed: Invalid root type"
            Write-Information "Found type '$($schemaObj.schema.type)' but expected 'object'"
            throw "Invalid schema: Root schema type must be 'object'"
        }
        Write-Information "Schema type validated: object"

        # Properties must be defined
        Write-Information "Checking schema properties"
        if (-not $schemaObj.schema.properties -or $schemaObj.schema.properties.Count -eq 0) {
            Write-Error "Schema validation failed: No properties defined"
            throw "Invalid schema: No properties defined"
        }
        Write-Information "Found $($schemaObj.schema.properties.Count) schema properties"

        Write-Information "Schema validation completed successfully"
        Write-Information "Schema name: $($schemaObj.name)"
        Write-Information "Strict mode: $($schemaObj.strict)"

        return $true
    } catch {
        Write-Error "Error validating schema JSON: $_"
        throw "Invalid schema JSON: $_"
    }
}