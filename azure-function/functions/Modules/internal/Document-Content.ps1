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

# Function to extract text from PDF documents
function Expand-PdfContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [byte[]]$FileContent
    )

    $tempFilePath = $null
    try {
        # Create a temporary file to save the content
        $tempFilePath = [System.IO.Path]::GetTempFileName() + ".pdf"
        [System.IO.File]::WriteAllBytes($tempFilePath, $FileContent)

        # Extract text from the PDF
        $textContent = Convert-PDFToText -FilePath $tempFilePath

        if ([string]::IsNullOrWhiteSpace($textContent)) {
            throw "No content extracted from PDF"
        }

        return $textContent
    } catch {
        throw "Error extracting content from PDF: $_"
    } finally {
        # Clean up the temporary file
        if ($tempFilePath -and (Test-Path $tempFilePath)) {
            Remove-Item -Path $tempFilePath -Force -ErrorAction SilentlyContinue
        }
    }
}

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

# Function to import and process request content
function Import-RequestContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]$Request
    )

    Write-Information "Starting request content processing..."
    $contentType = $Request.Headers['Content-Type']
    Write-Information "Content-Type: $contentType"
    $extractedContent = @()

    if ($contentType -like 'multipart/form-data*') {
        Write-Information "Processing multipart/form-data request"
        $extractedContent = Get-MultipartContent -ContentType $contentType -RawBytes $Request.Body
    } else {
        Write-Information "Processing regular file upload"
        # Get filename from Content-Disposition header if available
        $fileName = if ($Request.Headers['Content-Disposition'] -match 'filename="([^"]+)"') {
            $matches[1]
        } else {
            'document'  # Extension will be added based on detected file type
        }

        Write-Information "Using filename: $fileName"
        $result = Export-DocumentContent -Content $Request.Body -FileName $fileName
        # Update filename if a type was detected
        if ($result.detectedType -ne '.bin') {
            $result.fileName = [System.IO.Path]::ChangeExtension($result.fileName, $result.detectedType)
        }
        $extractedContent = @($result)
    }

    if ($extractedContent.Count -eq 0) {
        throw "No content was extracted from any files"
    }

    return $extractedContent
}

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
