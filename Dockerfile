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

# Create a directory
RUN mkdir /config

# Set up default PUID and PGID
ENV PUID=1000
ENV PGID=1000

# Create a new group and user with the specified PUID and PGID
RUN addgroup --gid $PGID posterizarr && \
    adduser --disabled-password --gecos "" --uid $PUID --gid $PGID posterizarr && \
    chown -R posterizarr:posterizarr /config

# Switch to the new user
USER posterizarr

# Copy the PowerShell script into the container
COPY Start.ps1 .

# Set the entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "pwsh", "Start.ps1", "--"]
