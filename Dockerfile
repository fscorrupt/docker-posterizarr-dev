# https://mcr.microsoft.com/powershell/tags/list
# https://mcr.microsoft.com/en-us/product/powershell/tags

# Imagemagick 7.1.1.37
# pwsh 7.4.2
# Base Image
FROM ghcr.io/fscorrupt/posterizarr-im-pwsh:latest

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr

# Install PowerShell module
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease"

# Set up default PUID and PGID
ENV PUID=1000
ENV PGID=1000

# Create a non-root user and group
RUN addgroup -g $PGID posterizarr && \
    adduser -u $PUID -G posterizarr -h /home/posterizarr -s /bin/sh -D posterizarr
# Create directories and set ownership to the non-root user
RUN mkdir -p /home/posterizarr/config /home/posterizarr/assets && \
    chown -R posterizarr:posterizarr /home/posterizarr

# Copy the PowerShell script into the container
COPY Start.ps1 /home/posterizarr/Start.ps1

# Set user and working directory
USER posterizarr
WORKDIR /home/posterizarr

# Set the entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "pwsh", "Start.ps1", "--"]
