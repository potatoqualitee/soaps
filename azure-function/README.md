# AI Document Analysis Function

An Azure Function that leverages AI to analyze documents and extract structured metadata. This function is particularly useful for automating document classification and metadata tagging in SharePoint document libraries.

## Overview

This solution consists of two Azure Function endpoints:

- `/api/extract` - Extracts text content from documents
- `/api/process` - Analyzes the content using AI based on a provided schema

## Real World Usage

A common use case is automatically tagging legal documents in SharePoint with relevant metadata:

```powershell
# Point to your document
$filePath = "C:\path\to\Legal_Opinion_Civil_Dispute.docx"

# Function endpoints
$uri = "https://your-function.azurewebsites.net/api/process"
# or for local testing
$uri = "http://localhost:7071/api/process"

# Send document for analysis
$params = @{
    Uri         = $uri
    Method      = 'Post'
    Headers     = @{
        'x-functions-key' = $functionKey
        'x-custom-schema' = $legalSchema
    }
    InFile      = $filePath
    ContentType = "application/octet-stream"
}

# Get AI-generated metadata
$result = Invoke-RestMethod @params

# The result can then be used to update SharePoint metadata
# Fields like area_of_law, document_type, and keywords map directly to SharePoint columns
```

## Schema Definition

The included legal document schema demonstrates how to structure metadata requirements:

```powershell
$legalSchema = @{
    name = "legal_document_categorizer"
    strict = $true
    schema = @{
        type = "object"
        properties = @{
            area_of_law = @{
                type = "string"
                description = "What area of law does the document primarily belong to?"
                enum = @(
                    "Criminal Law", "Civil Law", "Contract Law", "Property Law",
                    "Family Law", "Labor and Employment Law", "Intellectual Property Law",
                    "Tax Law", "Constitutional Law", "Administrative Law"
                )
            }
            document_type = @{
                type = "string"
                description = "What type of legal document is this?"
                enum = @(
                    "Case Brief", "Legal Opinion", "Contract", "Statute", "Regulation",
                    "Court Filing", "Legal Memorandum", "Legal Article", "Legal News"
                )
            }
            parties_involved = @{
                type = "array"
                items = @{ type = "string" }
                description = "What are the names of the parties involved in this legal matter?"
            }
            court = @{
                type = "string"
                description = "Which court or jurisdiction does this document relate to?"
            }
            case_number = @{
                type = "string"
                description = "What case number is associated with this document, if applicable."
            }
            keywords = @{
                type = "array"
                items = @{ type = "string" }
                description = "What are some good keywords or tags for this document?"
            }
        }
        required = @(
            "area_of_law", "document_type", "parties_involved",
            "court", "case_number", "keywords"
        )
        additionalProperties = $false
    }
}
```

The schema can be customized to match your SharePoint library columns or other metadata requirements.

## Setup

1. Deploy the Azure Function to your subscription
2. Get the function key from Azure Portal
3. Configure your SharePoint columns to match the schema properties
4. Update your scripts with the correct function URL and key

## Development

For local testing:
```powershell
$uri = "http://localhost:7071/api/extract"
$processUri = "http://localhost:7071/api/process"
```

## Security Notes

- Store function keys securely
- Use HTTPS in production environments
- Keep credentials out of source control
- Consider implementing additional authentication for SharePoint integration

## Error Handling

Standard HTTP status codes:
- 200: Success
- 400: Bad Request
- 401: Unauthorized
- 500: Internal Server Error

For troubleshooting, check the Azure Function logs in the portal.