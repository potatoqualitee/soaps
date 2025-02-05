$PSDefaultParameterValues["*:Confirm"] = $false
$PSDefaultParameterValues["*:Force"] = $true

# Check if modules are already installed
if (-not (Get-Module -ListAvailable -Name psopenai)) {
    Write-Output "Installing PowerShell dependencies..."
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module Pester, aitoolkit
    Install-Module psopenai
    Install-Module finetuna
}

# Reload profile with some settings we need
. $profile
