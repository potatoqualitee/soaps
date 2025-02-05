# Use the .NET 9 SDK base image
FROM mcr.microsoft.com/dotnet/sdk:9.0

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    python3-pip \
    universal-ctags \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Install PowerShell
RUN curl -sSL https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -o packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install .NET SDK 9.0 only if not already installed
RUN if ! dotnet --version 2>/dev/null | grep -q '^9'; then \
    curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh && \
    chmod +x dotnet-install.sh && \
    ./dotnet-install.sh --channel 9.0 --install-dir /usr/share/dotnet && \
    rm dotnet-install.sh; \
    else \
    echo ".NET SDK 9.0 is already installed"; \
    fi

# Create symbolic link only if it doesn't exist
RUN [ ! -e /usr/bin/dotnet ] && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet || echo "Symlink already exists"

# Create the devcontainer user and home directory
RUN useradd -m -s /bin/bash devcontainer

# Prepare directories, copy scripts, set permissions, and change ownership
RUN mkdir -p /home/devcontainer/.config/powershell && \
    chown -R devcontainer:devcontainer /home/devcontainer

COPY ./scripts/*.ps1 /home/devcontainer/

# Copy profile.ps1 to various profile locations
RUN cp /home/devcontainer/profile.ps1 /home/devcontainer/.config/powershell/Microsoft.PowerShell_profile.ps1 && \
    cp /home/devcontainer/profile.ps1 /home/devcontainer/.config/powershell/Microsoft.dotnet-interactive_profile.ps1 && \
    cp /home/devcontainer/profile.ps1 /home/devcontainer/.config/powershell/Microsoft.VSCode_profile.ps1 && \
    chmod +x /home/devcontainer/*.ps1 && \
    chown -R devcontainer:devcontainer /home/devcontainer

# Set default user and working directory
USER devcontainer
WORKDIR /home/devcontainer

# Set default shell to PowerShell
CMD ["pwsh"]
