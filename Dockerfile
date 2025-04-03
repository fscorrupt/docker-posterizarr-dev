FROM python:3.13-slim

ARG TARGETARCH
ARG VENDOR
ARG VERSION

ENV UMASK="0002" \
    TZ="Europe/Berlin" \
    POWERSHELL_DISTRIBUTION_CHANNEL="PSDocker" \
    PosterizarrNonRoot="TRUE" \
    PSModuleAnalysisCacheEnabled="false" \
    PSModuleAnalysisCachePath=""

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        curl \
        catatonit \
        imagemagick \
        libmagickcore-dev \
        libmagickwand-dev \
        ghostscript \
        libjpeg62-turbo \
        tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && pip install apprise \
    && mkdir -p /config \
    && chmod 755 /config \
    && chown -R nobody:nogroup /config && chmod -R 777 /config \
    
# Manually download and install PowerShell
RUN wget https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell_7.5.0-1.deb_amd64.deb \
    && dpkg -i powershell_7.5.0-1.deb_amd64.deb \
    && apt-get install -f -y \
    && rm powershell_7.5.0-1.deb_amd64.deb \
    && chmod -R 755 /usr/local/share/powershell \
    && mkdir -p /.local/share/powershell/PSReadLine && \
    chown -R nobody:nogroup /.local && \
    chmod -R 777 /.local
    
# Create directories inside /config
RUN mkdir -p /config/Logs /config/temp /config/watcher /config/test

# Copy application files
COPY entrypoint.sh /entrypoint.sh
COPY Start.ps1 /Start.ps1
COPY donate.txt /donate.txt
COPY files/ /config/

# Fix file permissions
RUN chmod +x /entrypoint.sh \
    && chown nobody:nogroup /entrypoint.sh

USER nobody:nogroup

WORKDIR /config

VOLUME ["/config"]

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/fscorrupt/Posterizarr"
LABEL org.opencontainers.image.description="Posterizarr - Automated poster generation for Plex/Jellyfin/Emby media libraries"
LABEL org.opencontainers.image.licenses="GPL-3.0"
