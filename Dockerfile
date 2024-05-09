# Base Image
FROM mcr.microsoft.com/powershell:7.4-alpine-3.17

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source https://github.com/fscorrupt/docker-posterizarr

# Add the Edge Community repository and update
RUN echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
    && apk upgrade --update-cache --available \
    && apk add --no-cache \
        python3 \
        py3-pip \
        imagemagick-libs@edge \
        imagemagick@edge \
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
