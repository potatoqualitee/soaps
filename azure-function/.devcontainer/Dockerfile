ARG VARIANT=7.4
FROM mcr.microsoft.com/azure-functions/powershell:4-powershell${VARIANT}-core-tools

# Install necessary packages and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    powershell-lts \
    dotnet-sdk-8.0 \
    dotnet-sdk-9.0 \
    git \
    python3-pip \
    universal-ctags && \
    rm -rf /var/lib/apt/lists/*

# Install PowerShell modules globally
RUN pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name PSWriteOffice, PSWritePDF, PSOpenAI -Scope AllUsers -Force -SkipPublisherCheck -AcceptLicense"

# Switch to vscode to avoid permission issues
USER vscode

# Ensure PowerShell profiles are linked correctly
RUN mkdir -p /home/vscode/.config/powershell && \
    ln -s /workspaces/soaps/azure-function/functions/profile.ps1 /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1 && \
    ln -s /workspaces/soaps/azure-function/functions/profile.ps1 /home/vscode/.config/powershell/Microsoft.dotnet-interactive_profile.ps1 && \
    ln -s /workspaces/soaps/azure-function/functions/profile.ps1 /home/vscode/.config/powershell/Microsoft.VSCode_profile.ps1

ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="/usr/share/dotnet:${PATH}"