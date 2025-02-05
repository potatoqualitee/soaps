# Azure Function for Document Processing

An Azure Function app that handles document content extraction and structured data processing using AI. It's designed to showcase how to use AI models (OpenAI, Azure OpenAI, or other compatible endpoints) to extract structured data from documents.

## What it Does

Takes documents (PDFs, Word docs, etc), extracts their content, and uses AI to convert that content into structured data based on your schema. For example, you could:
- Extract specific fields from legal documents
- Parse financial reports into database-ready format
- Convert unstructured text into categorized data
- Process document metadata automatically

## Requirements

### Environment Variables

- `API_KEY` - Your OpenAI API key
- `API_BASE` - API base URL (optional, defaults to OpenAI)
- `Model` - Model to use (e.g., "gpt-4o", "gpt-4o-mini")
- `AZURE_FUNCTION_KEY` - Function key for auth

### Dev Container Setup

The dev container includes:
- PowerShell 7+
- Azure Functions Core Tools
- Azure CLI
- Required PowerShell modules

## Quick Start

1. Set required environment variables
2. Define your schema (see example below)
3. Send documents to process

```powershell
# Define a schema for the data you want to extract
$schema = @{
    name = "legal_document_categorizer"
    strict = $true
    schema = @{
        type = "object"
        properties = @{
            area_of_law = @{
                type = "string"
                enum = @(
                    "Criminal Law", "Civil Law", "Contract Law"
                )
            }
            document_type = @{
                type = "string"
                enum = @(
                    "Case Brief", "Legal Opinion", "Contract"
                )
            }
            parties_involved = @{
                type = "array"
                items = @{ type = "string" }
            }
        }
        required = @("area_of_law", "document_type", "parties_involved")
    }
}

# Process some documents
Get-ChildItem ./docs |
    Select-Object -First 2 |
    Invoke-DocProcessing -Schema $schema
```

## How it Works

1. **Extract Endpoint** (`/api/extract`)
   - Accepts documents via POST
   - Extracts text content using the internal module
   - Returns raw text for further processing

2. **Process Endpoint** (`/api/process`)
   - Accepts documents and schema via POST
   - Uses AI to convert text into structured data
   - Returns JSON matching your schema

## Using Different AI Providers

The function works with any AI provider that implements OpenAI-compatible endpoints:

- **OpenAI**: Set `API_KEY` only
- **Azure OpenAI**: Set both `API_KEY` and `API_BASE` (https://xyz.openai.azure.com)
- **GitHub Models**: Set `API_KEY` with your GitHub PAT and `API_BASE` (https://models.github.ai/inference)
- **Other Compatible APIs**: Configure base URL and key as needed

## Structured Outputs vs Function Calls

This implementation uses structured outputs which is like asking "give me data in exactly this format" rather than function calls which are more conversational. Think of it as:

Structured Output:
```json
{
    "area_of_law": "Criminal Law",
    "document_type": "Case Brief",
    "parties_involved": ["State of Louisiana", "Tee Deaux"]
}
```

vs Function Call:
```
User: What kind of document is this?
AI: It appears to be a criminal case brief.
User: Who are the parties?
AI: Louisiana is prosecuting Tee Deaux.
```

Structured outputs are more efficient for data extraction tasks because they:
- Return data in a consistent format
- Don't require multiple exchanges
- Can map directly to database schemas
- Scale better for batch processing