# Base Image
# https://mcr.microsoft.com/v2/powershell/tags/list
FROM mcr.microsoft.com/powershell:7.4-alpine-3.17
ENV TINI_VERSION=v0.19.0
ARG TARGETARCH
# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr
    
# Add the Edge Community repository and update
RUN echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
    && apk upgrade --update-cache --available \
    && apk update \
    && apk add --no-cache \
        python3 \
        py3-pip \
        libjpeg-turbo-dev \
        imagemagick-libs@edge \
        imagemagick@edge \
        docker-cli \
    && wget -O /tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${TARGETARCH} \
    && chmod +x /tini
# Install Python library
RUN pip3 install apprise

# Install PowerShell module
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease"

# Create a directory
RUN mkdir /config

# Copy the PowerShell script into the container
COPY Start.ps1 .

# Set the entrypoint
ENTRYPOINT ["/tini", "-s", "pwsh", "Start.ps1", "--"]
