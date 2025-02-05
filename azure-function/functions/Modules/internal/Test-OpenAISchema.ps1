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