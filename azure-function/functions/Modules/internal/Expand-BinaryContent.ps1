# Function to extract text from binary content
function Expand-BinaryContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [byte[]]$FileContent
    )

    try {
        # Try UTF-8 first
        try {
            $textContent = [System.Text.Encoding]::UTF8.GetString($FileContent)
            if (-not [string]::IsNullOrWhiteSpace($textContent) -and $textContent -match '[\p{L}\p{N}]') {
                return $textContent
            }
        } catch {
            # Ignore UTF-8 decoding errors
        }

        # Try ASCII as fallback
        try {
            $textContent = [System.Text.Encoding]::ASCII.GetString($FileContent)
            if (-not [string]::IsNullOrWhiteSpace($textContent) -and $textContent -match '[\p{L}\p{N}]') {
                return $textContent
            }
        } catch {
            # Ignore ASCII decoding errors
        }

        # If no readable text found, return a description of the binary content
        return "Binary content: $($FileContent.Length) bytes"
    } catch {
        throw "Error processing binary content: $_"
    }
}