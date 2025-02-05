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