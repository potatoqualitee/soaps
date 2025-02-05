# Document Processing with Azure Functions

## End-User Guide

This project demonstrates how to integrate language models into your DevOps workflow for practical document automation. It shows DevOps engineers how they can use tools and services provided by OpenAI, Azure OpenAI, or GitHub Models, right in their pipelines. For example, automatically extracting and structuring content from SharePoint documents through simple POST requests.

### Setup Instructions

#### 1. Start the DevContainer
1. Open VS Code
2. Click the green button in the bottom-left corner (or press F1 and type "Dev Containers: Reopen in Container")
3. Wait for the container to build and start

#### 2. Configure Settings
1. Navigate to the `functions` directory
2. Copy the example settings file to create your local settings:
   ```bash
   cp local.settings.json.example local.settings.json
   ```
3. Edit `local.settings.json` and update the following values:
   - `API_KEY`: OpenAI-compatible API key (works with OpenAI API key, Azure OpenAI key, or GitHub PAT)
   - `API_BASE`: API base URL (OpenAI by default, or use Azure OpenAI/GitHub Models URL)
   - `AZURE_FUNCTION_KEY`: Your Azure Function key

#### 3. Start Azure Functions
1. In VS Code, click on "Terminal" in the menu bar
2. Click the "+" icon to open a new terminal
3. Select "Azure Functions" from the terminal options
4. Wait for the Functions host to start and display the endpoints

#### 4. Run the Demo
1. Open `demo.ipynb` in VS Code
2. Execute the notebook cells sequentially to see how language models can help automate document processing tasks

### Supported Document Types
- Microsoft Word (.docx)
- Microsoft Excel (.xlsx)
- Microsoft PowerPoint (.pptx)
- PDF (recommended for non-Azure Functions environments)

---

## Developer Documentation

An Azure Function app that shows DevOps engineers how to integrate modern language models into their automation pipelines. Perfect for document management systems, it extracts and structures content using models from OpenAI, Azure OpenAI, or GitHub, demonstrating practical applications of these tools in your deployment workflows.

### What it Does

Automates document processing tasks by extracting content and converting it into structured data based on your schema. Example automation scenarios:
- Processing legal document repositories
- Batch processing financial reports
- Converting unstructured documents into structured data
- Automated metadata extraction

### Requirements

#### Environment Variables
- `API_KEY` - OpenAI-compatible API key (works with OpenAI API key, Azure OpenAI key, or GitHub PAT)
- `API_BASE` - API base URL:
  - OpenAI: leave empty
  - Azure OpenAI: use `https://your-resource.openai.azure.com`
  - GitHub Models: use `https://models.github.ai/inference`
- `Model` - Model to use (e.g., "gpt-4o", "gpt-4o-mini")
- `AZURE_FUNCTION_KEY` - Function key for auth

#### Dev Container Setup
The dev container includes:
- PowerShell 7+
- Azure Functions Core Tools
- Azure CLI
- Required PowerShell modules

### Quick Start

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

### How it Works

1. **Extract Endpoint** (`/api/extract`)
   - Accepts documents via POST
   - Extracts text content using the internal module
   - Returns raw text for further processing

2. **Process Endpoint** (`/api/process`)
   - Accepts documents and schema via POST
   - Uses language models to convert text into structured data
   - Returns JSON matching your schema

### Using Different API Providers

The function integrates with any provider offering OpenAI-compatible endpoints:

- **OpenAI**: Set `API_KEY` only
- **Azure OpenAI**: Set both `API_KEY` and `API_BASE` (https://xyz.openai.azure.com)
- **GitHub Models**: Set `API_KEY` with your GitHub PAT and `API_BASE` (https://models.github.ai/inference)
- **Other Compatible APIs**: Configure base URL and key as needed

### Structured Outputs vs Function Calls

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