# Base Image
FROM ghcr.io/fscorrupt/posterizarr-im-pwsh:latest

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr
LABEL imagemagick.version=7.1.1.38
LABEL powershell.version=7.4.2

# Environment Variables
ENV PUID=1000
ENV PGID=1000

# Install PowerShell module
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease"

# Create group and user based on PUID and PGID
RUN groupadd -g ${PGID} posterizarr && \
    useradd -u ${PUID} -g posterizarr -m posterizarr && \
    mkdir /config && \
    chown -R posterizarr:posterizarr /config

# Set working directory
WORKDIR /home/posterizarr

# Copy the PowerShell script into the container
COPY Start.ps1 /home/posterizarr/Start.ps1

# Set permissions on the script
RUN chmod +x /home/posterizarr/Start.ps1 && \
    chown posterizarr:posterizarr /home/posterizarr/Start.ps1

# Set the entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "pwsh", "Start.ps1", "--"]

# Run the container as the created user
USER posterizarr
