# Function to determine file type and extract content
function Get-DocumentContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [byte[]]$FileContent,

        [Parameter(Mandatory)]
        [string]$FileName
    )

    $fileExtension = [System.IO.Path]::GetExtension($FileName).ToLower()
    Write-Information "Processing file with extension: $fileExtension"
    $detectedExtension = $fileExtension

    # If file extension is missing, octet-stream, or bin, try to detect the actual type
    if ([string]::IsNullOrWhiteSpace($fileExtension) -or $fileExtension -eq ".octet-stream" -or $fileExtension -eq ".bin") {
        Write-Information "Attempting to detect file type from content..."
        if ($FileContent.Length -ge 4) {
            $header = $FileContent[0..3]

            # Define known file signatures
            $signatures = @{
                'PDF'    = @{
                    Extension = '.pdf'
                    Header    = [byte[]]@(0x25, 0x50, 0x44, 0x46) # %PDF
                }
                'Office' = @{
                    Extension = '.docx' # Default to .docx, will be refined later
                    Header    = [byte[]]@(0x50, 0x4B, 0x03, 0x04) # PK..
                }
            }

            # Check file signature against known types
            $typeDetected = $false
            foreach ($type in $signatures.Keys) {
                if ((@($header) -join ",") -eq ($signatures[$type].Header -join ",")) {
                    Write-Information "Detected file type: $type"

                    # For Office files, try to determine specific type
                    if ($type -eq 'Office') {
                        # Create a temporary file to inspect content
                        $tempPath = [System.IO.Path]::GetTempFileName()
                        try {
                            [System.IO.File]::WriteAllBytes($tempPath, $FileContent)
                            $zip = [System.IO.Compression.ZipFile]::OpenRead($tempPath)

                            # Check for specific Office file markers
                            if ($zip.Entries.Name -contains "word/document.xml") {
                                $detectedExtension = '.docx'
                                Write-Information "Detected Word document"
                            } elseif ($zip.Entries.Name -contains "xl/workbook.xml") {
                                $detectedExtension = '.xlsx'
                                Write-Information "Detected Excel document"
                            } elseif ($zip.Entries.Name -contains "ppt/presentation.xml") {
                                $detectedExtension = '.pptx'
                                Write-Information "Detected PowerPoint document"
                            } else {
                                $detectedExtension = '.docx' # Default to Word if uncertain
                                Write-Information "Unknown Office format, defaulting to Word"
                            }
                        } catch {
                            Write-Warning "Error inspecting Office file: $_"
                            $detectedExtension = '.docx' # Default to Word if inspection fails
                        } finally {
                            if ($zip) { $zip.Dispose() }
                            if (Test-Path $tempPath) { Remove-Item -Path $tempPath -Force }
                        }
                    } else {
                        $detectedExtension = $signatures[$type].Extension
                    }
                    $typeDetected = $true
                    break
                }
            }

            if (-not $typeDetected) {
                Write-Information "No known file type detected, treating as binary"
                return @{
                    Content           = Expand-BinaryContent -FileContent $FileContent
                    DetectedExtension = '.bin'
                }
            }
        } else {
            Write-Information "Content too short for type detection, treating as binary"
            return @{
                Content           = Expand-BinaryContent -FileContent $FileContent
                DetectedExtension = '.bin'
            }
        }
    }

    # Process based on detected or provided extension
    Write-Information "Processing with extension: $detectedExtension"
    switch -Regex ($detectedExtension) {
        "\.(docx|xlsx|pptx)$" {
            $content = Expand-OfficeContent -FileContent $FileContent -FileExtension $detectedExtension
            return @{
                Content           = $content
                DetectedExtension = $detectedExtension
            }
        }
        "\.pdf$" {
            $content = Expand-PdfContent -FileContent $FileContent
            return @{
                Content           = $content
                DetectedExtension = $detectedExtension
            }
        }
        default {
            Write-Warning "Unknown file type: $detectedExtension, attempting binary processing"
            $content = Expand-BinaryContent -FileContent $FileContent
            return @{
                Content           = $content
                DetectedExtension = $detectedExtension
            }
        }
    }
}