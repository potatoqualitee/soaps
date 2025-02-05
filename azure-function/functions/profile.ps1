# Set env vars
if ($env:OPENAI_API_KEY) {
    $env:API_KEY = $env:OPENAI_API_KEY
    $env:API_BASE = $env:OPENAI_API_BASE
}

# Import required modules for document extraction
Import-Module -Name PSOpenAI -Force -ErrorAction SilentlyContinue
Import-Module -Name PSWriteOffice -Force -ErrorAction SilentlyContinue

if ($profile -notmatch 'dotnet-interactive') {
    Import-Module -Name PSWritePDF -Force -ErrorAction SilentlyContinue
}

if ((Get-Module internal -ListAvailable)) {
    Import-Module internal -Force
} else {
    # Try to locate and import the internal module
    $possiblePaths = @()

    # Add PSScriptRoot path if available
    if ($PSScriptRoot) {
        $possiblePaths += Join-Path $PSScriptRoot "Modules/internal/internal.psm1"
    }

    # Add known devcontainer path
    $possiblePaths += "/workspaces/soaps/azure-function/functions/Modules/internal/internal.psm1"

    # Try relative path from current directory
    $possiblePaths += "./functions/Modules/internal/internal.psm1"
    $possiblePaths += "./Modules/internal/internal.psm1"
    $possiblePaths += "../Modules/internal/internal.psm1"

    # Add Azure Functions paths if environment variables exist
    if ($env:AzureWebJobsScriptRoot) {
        $possiblePaths += Join-Path $env:AzureWebJobsScriptRoot "Modules/internal/internal.psm1"
    }
    if ($env:HOME) {
        $possiblePaths += Join-Path $env:HOME "site/wwwroot/Modules/internal/internal.psm1"
    }

    # Add verbose logging
    Write-Information "Looking for internal module in these locations:"
    foreach ($path in $possiblePaths) {
        Write-Information "  - $path (Exists: $(Test-Path $path))"
    }

    $moduleFound = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            try {
                Import-Module $path -Force -ErrorAction Stop
                Write-Information "Loaded internal module from: $path"
                $moduleFound = $true
                break
            } catch {
                Write-Warning "Failed to import from $path"
            }
        }
    }
}
# $env:PATH = "$HOME/.dotnet/tools:$env:PATH"