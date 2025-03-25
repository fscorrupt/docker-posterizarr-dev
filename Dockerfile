# Base Image
# https://mcr.microsoft.com/en-us/product/powershell/tags
# Imagemagick 7.1.1.46
FROM lscr.io/linuxserver/baseimage-ubuntu:jammy

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr-dev
LABEL imagemagick.version=7.1.1.46
LABEL powershell.version=7.5.0

# Set the distribution channel for PowerShell
ENV POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Ubuntu-22.04
ENV TZ=Europe/Berlin
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install dependencies
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        python3 \
        python3-pip \
        tini \
        docker.io \
        wget \
        tzdata \
        libicu70 \
        liblttng-ust1 \
    && apt-get clean

    # Download and install Microsoft repository for PowerShell
RUN wget -q "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb" && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell

# Install ImageMagick using BuildKit cache
RUN --mount=type=cache,target=/var/cache/imagemagick \
    t=$(mktemp) && \
    wget 'https://dist.1-2.dev/imei.sh' -qO "$t" && \
    bash "$t" && \
    rm "$t"

# Install Python library
RUN pip3 install apprise

# Install PowerShell module
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease -Scope AllUsers"

# Copy the s6-overlay run script and other necessary files
COPY ./root/ /

VOLUME /config
