# Internal Module

## Overview

PowerShell module for document processing and content extraction in Azure Functions. Works with Office docs (Word, Excel, PowerPoint), PDFs, and binary files.

## Main Features

- Content extraction from Office docs, PDFs, and binary files
- Automatic file type detection
- Azure Functions request/response handling
- OpenAI integration
- Multipart form data handling

## Commands

### Document Processing
- `Get-DocumentContent` - Extracts content from files with automatic format detection
- `Export-DocumentContent` - Pipeline-friendly document content extraction
- `Expand-OfficeContent` - Handles Word, Excel, and PowerPoint documents
- `Expand-PdfContent` - Extracts text from PDF files
- `Expand-BinaryContent` - Processes binary files with text content detection
- `Import-RequestContent` - Processes incoming HTTP request content
- `Invoke-DocProcessing` - Processes documents through Azure Function endpoints

### Request Processing
- `Test-RequestValidation` - Validates incoming requests
- `Get-MultipartContent` - Handles multipart form data
- `Get-FileContent` - Retrieves file content from requests
- `Get-HeaderValue` - Extracts specific header values

### Schema & OpenAI Integration
- `ConvertTo-OpenAISchema` - Converts data to OpenAI-compatible schema
- `Get-OpenAIStructuredOutput` - Processes text through OpenAI
- `Test-OpenAISchema` - Validates schema structure

### HTTP Response Helpers
- `Send-OkResponse` - Returns successful response (200)
- `Send-BadRequest` - Returns bad request response (400)
- `Send-InternalServerError` - Returns server error response (500)

## Examples

### Basic File Upload
```powershell
# Using InFile parameter (simple)
$params = @{
    Uri         = "http://localhost:7071/api/extract"
    Method      = "Post"
    Headers     = @{ 'x-functions-key' = $functionKey }
    InFile      = $filePath
    ContentType = "application/octet-stream"
}
Invoke-RestMethod @params | ConvertTo-Json -Depth 5
```

### Multipart Form Data Upload
```powershell
# Create multipart form data with file
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"
$fileName = Split-Path $filePath -Leaf

$memoryStream = New-Object System.IO.MemoryStream
$encoding = [System.Text.Encoding]::UTF8
$fileBytes = [System.IO.File]::ReadAllBytes($filePath)

# Write form headers
$header = @(
    "--$boundary",
    "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
    "Content-Type: application/octet-stream",
    ""
) -join $LF
$headerBytes = $encoding.GetBytes($header + $LF)
$memoryStream.Write($headerBytes, 0, $headerBytes.Length)

# Write file content and close boundary
$memoryStream.Write($fileBytes, 0, $fileBytes.Length)
$footerBytes = $encoding.GetBytes("$LF--$boundary--$LF")
$memoryStream.Write($footerBytes, 0, $footerBytes.Length)

# Send request
$params = @{
    Uri = "http://localhost:7071/api/extract"
    Method = "Post"
    ContentType = "multipart/form-data; boundary=$boundary"
    Headers = @{ 'x-functions-key' = $functionKey }
    Body = $memoryStream.ToArray()
}
Invoke-RestMethod @params
```

### Legal Document Processing
```powershell
# Define document schema
$legalSchema = @{
    name = "legal_document_categorizer"
    strict = $true
    schema = @{
        type = "object"
        properties = @{
            area_of_law = @{
                type = "string"
                enum = @("Criminal Law", "Civil Law", "Contract Law", "Property Law")
            }
            document_type = @{
                type = "string"
                enum = @("Case Brief", "Legal Opinion", "Contract", "Statute")
            }
            parties_involved = @{
                type = "array"
                items = @{ type = "string" }
            }
        }
        required = @("area_of_law", "document_type", "parties_involved")
    }
}

# Process document with schema
$params = @{
    Uri = "http://localhost:7071/api/process"
    Method = "Post"
    Headers = @{
        'x-functions-key' = $functionKey
        'x-custom-schema' = ($legalSchema | ConvertTo-Json -Depth 20 -Compress)
    }
    InFile = $filePath
    ContentType = "application/octet-stream"
}
Invoke-RestMethod @params | ConvertTo-Json -Depth 20