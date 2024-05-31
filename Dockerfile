# Base Image
# https://mcr.microsoft.com/v2/powershell/tags/list
FROM mcr.microsoft.com/powershell:7.4-alpine-3.17

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source https://github.com/fscorrupt/docker-posterizarr

# Create a user with specified UID and GID
ARG PUID=1000
ARG PGID=1000

# Add the Edge Community repository and update
RUN echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
    && apk upgrade --update-cache --available \
    && apk update \
    && apk add --no-cache \
        shadow \
        python3 \
        py3-pip \
        libjpeg-turbo-dev \
        imagemagick-libs@edge \
        imagemagick@edge \
        tini \
        docker-cli
        
# Install Python library as posterizarr user
RUN pip3 install apprise

# Install PowerShell module as posterizarr user
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease"

# Create the user and group after installing necessary packages
RUN addgroup -g ${PGID} posterizarrgroup && \
    adduser -u ${PUID} -G posterizarrgroup -h /home/posterizarr -D posterizarr

# Switch to the new user
USER posterizarr

# Create a directory as posterizarr user
RUN mkdir /config

# Copy the PowerShell script into the container
COPY Start.ps1 .

# Set the entrypoint
ENTRYPOINT ["/sbin/tini", "-s", "pwsh", "Start.ps1", "--"]
