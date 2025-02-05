function Get-MultipartContent {
    param (
        [Parameter(Mandatory)]
        [string]$ContentType,
        [Parameter(Mandatory)]
        [byte[]]$RawBytes,
        [string]$OverrideFileName
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
            $sectionFileName = $OverrideFileName ?? $matches['filename']
            if ($sectionFileName) {
                $fileBytes = Get-SectionFileBytes -Section $section -BodyContent $bodyContent -RawBytes $rawBytes
                $extractedContent += Get-FileContent -FileBytes $fileBytes -FileName $sectionFileName
            }
        }
    }

    return $extractedContent
}