# Base Image
# https://mcr.microsoft.com/powershell/tags/list
# Imagemagick 7.1.1.36
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr

# Update the package list and install dependencies
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        python3 \
        python3-pip \
        tini \
        docker.io \
        wget

# Install ImageMagick using the external script
RUN t=$(mktemp) && \
    wget 'https://dist.1-2.dev/imei.sh' -qO "$t" && \
    bash "$t" --skip-aom && \
    rm "$t"

# Install Python library
RUN pip3 install apprise

# Install PowerShell module
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease"

# Create a directory
RUN mkdir /config

# Copy the PowerShell script into the container
COPY Start.ps1 .

# Set the entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "pwsh", "Start.ps1", "--"]
