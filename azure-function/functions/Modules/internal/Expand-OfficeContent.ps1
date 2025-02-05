# Function to extract text from Office documents (Word, Excel, PowerPoint)
function Expand-OfficeContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [byte[]]$FileContent,

        [Parameter(Mandatory)]
        [string]$FileExtension
    )

    $tempFilePath = $null
    try {
        # Create a temporary file to save the content
        $tempFilePath = [System.IO.Path]::GetTempFileName() + $FileExtension
        [System.IO.File]::WriteAllBytes($tempFilePath, $FileContent)

        $textContent = @()

        switch -Regex ($FileExtension) {
            "\.docx" {
                $document = Get-OfficeWord -FilePath $tempFilePath
                if ($null -eq $document) {
                    throw "Failed to open Word document"
                }
                $textContent = $document.Paragraphs.Text
                $document.Dispose()
            }
            "\.xlsx" {
                $document = Get-OfficeExcel -FilePath $tempFilePath
                if ($null -eq $document) {
                    throw "Failed to open Excel document"
                }
                foreach ($worksheet in $document.Worksheets) {
                    foreach ($row in $worksheet.Rows) {
                        $textContent += ($row.Cells.Text -join " ")
                    }
                }
                $document.Dispose()
            }
            "\.pptx" {
                $document = Get-OfficePowerPoint -FilePath $tempFilePath
                if ($null -eq $document) {
                    throw "Failed to open PowerPoint document"
                }
                foreach ($slide in $document.Slides) {
                    $textContent += ($slide.Shapes.Text -join " ")
                }
                $document.Dispose()
            }
        }

        if ($textContent.Count -eq 0) {
            throw "No content extracted from document"
        }

        return $textContent -join "`n"
    } catch {
        throw "Error extracting content from Office document: $_"
    } finally {
        # Clean up the temporary file
        if ($tempFilePath -and (Test-Path $tempFilePath)) {
            Remove-Item -Path $tempFilePath -Force -ErrorAction SilentlyContinue
        }
    }
}