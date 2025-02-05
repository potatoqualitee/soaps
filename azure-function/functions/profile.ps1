# using namespace System.Net

# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.

# Import-Module Az.Accounts -RequiredVersion '1.9.5'

if ($env:MSI_SECRET -and (Get-Module -ListAvailable Az.Accounts)) {
    Connect-AzAccount -Identity
}

# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# Import required modules for document extraction
Import-Module -Name PSOpenAI -Force -ErrorAction SilentlyContinue
Import-Module -Name PSWriteOffice -Force -ErrorAction SilentlyContinue

if ($profile -notmatch 'dotnet-interactive') {
    Import-Module -Name PSWritePDF -Force -ErrorAction SilentlyContinue
}

# Import internal module with HTTP response and document handling functions
$internalModulePath = "/workspaces/soaps/azure-function/functions/Modules/internal/internal.psm1"
if (Test-Path $internalModulePath) {
    Import-Module $internalModulePath -Force -ErrorAction Stop
    Write-Information "Loaded internal module from: $internalModulePath"
} else {
    throw "Internal module not found at: $internalModulePath"
}

# $env:PATH = "$HOME/.dotnet/tools:$env:PATH"