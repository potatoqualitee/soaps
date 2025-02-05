# Function to extract text from PDF documents
function Expand-PdfContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [byte[]]$FileContent
    )

    # Check if running in Azure Functions environment
    if ($env:AZURE_FUNCTIONS_ENVIRONMENT) {
        return @"
{
    "notice": "PDF processing is supported but currently disabled in Azure Functions environment.",
    "message": "For PDF processing in Azure Functions, please use the sample code in a non-Azure Functions environment.",
    "raw_content_length": $($FileContent.Length)
}
"@
    }

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