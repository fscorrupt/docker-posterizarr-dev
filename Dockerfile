# Base Image
FROM mcr.microsoft.com/powershell:7.4-alpine-3.17

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source https://github.com/fscorrupt/docker-posterizarr

# Install necessary tools
RUN apk update && apk add --no-cache \
    wget \
    ca-certificates

# Download and install ImageMagick directly
RUN wget https://nl.alpinelinux.org/alpine/edge/community/x86_64/imagemagick-7.1.1.32-r0.apk \
    && apk add --allow-untrusted imagemagick-7.1.1.32-r0.apk

# Continue with other installations
RUN apk add --no-cache \
    python3 \
    py3-pip \
    tini \
    docker-cli

# Install Python library
RUN pip3 install apprise

# Install PowerShell module
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease"

# Create a directory
RUN mkdir /config

# Copy the PowerShell script into the container
COPY Start.ps1 .

# Set the entrypoint
ENTRYPOINT ["/sbin/tini", "-s", "pwsh", "Start.ps1", "--"]
