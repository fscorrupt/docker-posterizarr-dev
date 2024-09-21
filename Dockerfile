# Base Image
FROM ghcr.io/fscorrupt/posterizarr-im-pwsh:latest

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr
LABEL imagemagick.version=7.1.1.38
LABEL powershell.version=7.4.2

# Install PowerShell module
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease -Scope AllUsers"

# Set working directory
WORKDIR /home/posterizarr

# Copy the PowerShell script into the container
COPY Start.ps1 /home/posterizarr/Start.ps1

# Set permissions on the script
RUN chmod +x /home/posterizarr/Start.ps1

# Set the entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "pwsh", "Start.ps1", "--"]
