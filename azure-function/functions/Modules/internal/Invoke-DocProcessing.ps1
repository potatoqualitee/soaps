function Invoke-DocProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ if (Test-Path $_) { $true } else { throw "File not found: $_" } })]
        [Alias("FullName")]
        [string[]]$FilePath,
        [string]$FunctionKey = $env:AZURE_FUNCTION_KEY,
        [string]$Model = $env:Model,
        [Parameter(Mandatory)]
        [hashtable]$Schema,
        [ValidateSet("extract", "process")]
        [string]$Action = "process",
        [string]$BaseUri = $env:AZURE_FUNCTION_API_BASE
    )

    process {
        Write-Verbose "Preparing request headers..."
        $headers = @{ 'x-functions-key' = $FunctionKey }

        if ($Action -eq "process") {
            Write-Verbose "Processing extracted data for legal categorization..."
            $compressedSchema = ($Schema | ConvertTo-Json -Depth 20 -Compress)
            $headers['x-custom-schema'] = $compressedSchema
        }

        $uri = "$BaseUri/$Action"
        Write-Verbose "Sending request to: $uri"

        foreach ($file in $FilePath) {
            $splat = @{
                Uri         = $uri
                Method      = "POST"
                Headers     = $headers
                InFile      = $file
                ContentType = "application/octet-stream"
            }
            Invoke-RestMethod @splat | ConvertTo-Json -Depth 20
        }
    }
}