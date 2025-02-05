# Function to import and process request content
function Import-RequestContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]$Request
    )

    Write-Information "Starting request content processing..."

    # Check for x-filename header first
    $overrideFileName = $Request.Headers['x-filename']
    if ($overrideFileName) {
        Write-Information "Using x-filename header: $overrideFileName"
    }

    $contentType = $Request.Headers['Content-Type']
    Write-Information "Content-Type: $contentType"
    $extractedContent = @()

    if ($contentType -like 'multipart/form-data*') {
        Write-Information "Processing multipart/form-data request"
        $extractedContent = Get-MultipartContent -ContentType $contentType -RawBytes $Request.Body -OverrideFileName $overrideFileName
    } elseif ($contentType -like 'application/json*') { # Add support for Power Platform JSON format
        Write-Information "Processing JSON request"
        try {
            # Parse the JSON body if it's not already an object
            $jsonBody = if ($Request.Body -is [string]) {
                $Request.Body | ConvertFrom-Json
            } else {
                $Request.Body
            }

            # Check if this is the Power Platform format
            if ($jsonBody.'content-type' -and $jsonBody.content) {
                Write-Information "Detected Power Platform document format"

                # Get the document content type
                $docContentType = $jsonBody.'content-type'
                Write-Information "Document content type: $docContentType"

                # Determine file extension based on content type
                $fileExtension = switch -Regex ($docContentType) {
                    'application/vnd\.openxmlformats-officedocument\.wordprocessingml\.document' { '.docx' }
                    'application/vnd\.openxmlformats-officedocument\.spreadsheetml\.sheet' { '.xlsx' }
                    'application/vnd\.openxmlformats-officedocument\.presentationml\.presentation' { '.pptx' }
                    'application/pdf' { '.pdf' }
                    default { '.bin' }
                }

                # Decode the base64 content
                $fileBytes = [Convert]::FromBase64String($jsonBody.content)
                Write-Information "Decoded content length: $($fileBytes.Length) bytes"

                # Use override filename or default
                $fileName = $overrideFileName ?? "document$fileExtension"
                $result = Export-DocumentContent -Content $fileBytes -FileName $fileName
                $extractedContent = @($result)
            } else {
                Write-Warning "JSON request doesn't match Power Platform format"
                throw "Invalid JSON format. Expected 'content-type' and 'content' fields."
            }
        } catch {
            Write-Error "Error processing JSON request: $_"
            throw
        }
    } else {
        Write-Information "Processing regular file upload"
        # Use override filename, or get from Content-Disposition, or use default
        $fileName = $overrideFileName
        if (-not $fileName) {
            $fileName = if ($Request.Headers['Content-Disposition'] -match 'filename="([^"]+)"') {
                $matches[1]
            } else {
                'document'  # Extension will be added based on detected file type
            }

            # Only modify extension for non-override filenames
            $result = Export-DocumentContent -Content $Request.Body -FileName $fileName
            if ($result.detectedType -ne '.bin') {
                $result.fileName = [System.IO.Path]::ChangeExtension($result.fileName, $result.detectedType)
            }
        } else {
            $result = Export-DocumentContent -Content $Request.Body -FileName $fileName
        }
        $extractedContent = @($result)
    }

    if ($extractedContent.Count -eq 0) {
        throw "No content was extracted from any files"
    }

    return $extractedContent
}