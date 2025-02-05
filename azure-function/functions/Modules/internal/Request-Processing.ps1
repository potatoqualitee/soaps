using namespace System.Net

function Test-RequestValidation {
    param (
        [Parameter(Mandatory)]
        [object]$Request
    )

    if (-not $Request.Body) {
        Write-Warning "Request validation failed: No content in request body"
        Send-BadRequest -Message "No content found in request"
        return $false
    }

    return $true
}

function Get-MultipartContent {
    param (
        [Parameter(Mandatory)]
        [string]$ContentType,
        [Parameter(Mandatory)]
        [byte[]]$RawBytes
    )

    if ($ContentType -notmatch 'boundary=(.+)$') {
        throw "No boundary found in multipart Content-Type header"
    }

    $boundary = "--" + $matches[1]
    Write-Information "Multipart boundary: $boundary"
    Write-Information "Raw request body length: $($rawBytes.Length) bytes"

    $bodyContent = [System.Text.Encoding]::UTF8.GetString($rawBytes)
    $sections = $bodyContent -split [regex]::Escape($boundary)
    $extractedContent = @()

    foreach ($section in $sections) {
        if (-not $section.Trim() -or $section.Trim() -eq '--') { continue }

        if ($section -match 'Content-Disposition:\s*form-data;\s*name="(?<name>[^"]*)"(;\s*filename="(?<filename>[^"]*)")?') {
            $fileName = $matches['filename']
            if ($fileName) {
                $fileBytes = Get-SectionFileBytes -Section $section -BodyContent $bodyContent -RawBytes $rawBytes
                $extractedContent += Get-FileContent -FileBytes $fileBytes -FileName $fileName
            }
        }
    }

    return $extractedContent
}

function Get-SectionFileBytes {
    param (
        [Parameter(Mandatory)]
        [string]$Section,
        [Parameter(Mandatory)]
        [string]$BodyContent,
        [Parameter(Mandatory)]
        [byte[]]$RawBytes
    )

    $headerEndPos = $section.IndexOf("`r`n`r`n")
    if ($headerEndPos -eq -1) { throw "Invalid section format" }

    $contentStartPos = $headerEndPos + 4
    $sectionStartPos = $bodyContent.IndexOf($section)
    $fileStartPos = $sectionStartPos + [System.Text.Encoding]::UTF8.GetByteCount($section.Substring(0, $contentStartPos))
    $fileEndPos = $sectionStartPos + [System.Text.Encoding]::UTF8.GetByteCount($section) - 2

    return $rawBytes[$fileStartPos..$fileEndPos]
}

function Get-FileContent {
    param (
        [Parameter(Mandatory)]
        [byte[]]$FileBytes,
        [Parameter(Mandatory)]
        [string]$FileName
    )

    Write-Information "Processing file: $fileName"
    Write-Information "File content length: $($fileBytes.Length) bytes"
    Write-Information "Starting content extraction pipeline..."

    try {
        $documentResult = Get-DocumentContent -FileContent $fileBytes -FileName $fileName

        # Check if the filename needs to be updated with the detected extension
        $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        $originalExt = [System.IO.Path]::GetExtension($fileName).ToLower()
        $detectedExt = $documentResult.DetectedExtension

        # If the original filename is document.bin or has no extension or .octet-stream extension,
        # update it with the detected extension
        if ($fileName -eq 'document.bin' -or [string]::IsNullOrWhiteSpace($originalExt) -or
            $originalExt -eq '.bin' -or $originalExt -eq '.octet-stream') {
            $updatedFileName = "$fileNameWithoutExt$detectedExt"
            Write-Information "Updated filename from '$fileName' to '$updatedFileName' based on detected type"
            $fileName = $updatedFileName
        }

        Write-Information "Successfully processed file: $fileName"
        return @{
            fileName = $fileName
            content  = $documentResult.Content
        }
    } catch {
        Write-Error "Failed to process file '$fileName': $_"
        throw
    }
}

function Get-HeaderValue {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Headers,
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$DefaultValue
    )

    # Convert headers to case-insensitive for lookup
    $headerDict = @{}
    $Headers.GetEnumerator() | ForEach-Object {
        $headerDict[$_.Key.ToLower()] = $_.Value
    }

    # Look up using lowercase name
    $lookupName = $Name.ToLower()
    if ($headerDict.ContainsKey($lookupName)) {
        return $headerDict[$lookupName]
    }
    return "$DefaultValue"
}