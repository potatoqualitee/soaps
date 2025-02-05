# Reusable function for document content extraction
function Export-DocumentContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [byte[]]$Content,

        [Parameter(Mandatory)]
        [string]$FileName
    )

    begin {
        Write-Information "Starting document content extraction..."
    }

    process {
        try {
            Write-Information "Processing file: $FileName"
            Write-Information "Content length: $($Content.Length) bytes"

            $result = Get-DocumentContent -FileContent $Content -FileName $FileName

            Write-Information "Content extracted successfully"
            return @{
                fileName     = $FileName
                content      = $result.Content
                detectedType = $result.DetectedExtension
            }
        } catch {
            Write-Error "Error extracting document content: $_"
            throw
        }
    }

    end {
        Write-Information "Document content extraction completed"
    }
}