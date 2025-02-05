function ConvertTo-OpenAISchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$MetadataJson,
        [string]$SchemaName = "file_metadata"
    )

    process {
        Write-Warning "Converting to OpenAI schema"
        try {
            # Convert JSON string to PowerShell object
            $metadata = $MetadataJson | ConvertFrom-Json

            # Initialize OpenAI structured output schema
            $openAISchema = @{
                name   = $SchemaName
                strict = $true
                schema = @{
                    type                 = "object"
                    properties           = @{}
                    required             = @()
                    additionalProperties = $false
                }
            }

            # Iterate over metadata properties
            foreach ($key in $metadata.PSObject.Properties.Name) {
                $value = $metadata.$key
                $dataType = "string"  # Default to string

                # Infer data types
                if ($value -match '^\d+$') {
                    $dataType = "integer"
                } elseif ($value -match '^\d+\.\d+$') {
                    $dataType = "number"
                } elseif ($value -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') {
                    $dataType = "string"
                    $format = "date-time"
                }

                # Add property to schema
                $openAISchema.schema.properties[$key] = @{
                    type        = $dataType
                    description = "Metadata property: $key"
                }

                # If it's a date-time, add format
                if ($format) {
                    $openAISchema.schema.properties[$key].format = $format
                    $format = $null
                }

                # Add required fields (assuming all are required)
                $openAISchema.schema.required += $key
            }

            # Return the schema
            return $openAISchema
        } catch {
            Write-Error "Error converting metadata to OpenAI schema: $_"
            throw
        }
    }
}