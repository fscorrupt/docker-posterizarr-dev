# Base Image
FROM ghcr.io/fscorrupt/posterizarr-im-pwsh-lsio:latest

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr
LABEL imagemagick.version=7.1.1.38
LABEL powershell.version=7.4.5

# Set the distribution channel for PowerShell
ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Ubuntu-22.04

# Install PowerShell module
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease -Scope AllUsers"

# Copy the s6-overlay run script and other necessary files
COPY ./root/ /

VOLUME /config
