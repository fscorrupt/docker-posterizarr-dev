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

RUN apt-get update && apt-get install -y --no-install-recommends \
        catatonit \
        curl \
        imagemagick \
        libmagickcore-dev \
        libmagickwand-dev \
        ghostscript \
        fonts-dejavu \
        fonts-freefont-ttf \
        pango \
        libpango1.0-0 \
        cairo \
        libfribidi0 \
        harfbuzz \
        icu-devtools \
        tzdata \
        powershell \
    && pwsh -NoProfile -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
        Install-Module -Name FanartTvAPI -Scope AllUsers -Force" \
    && rm -rf /var/lib/apt/lists/* \
    && chmod -R 755 /usr/local/share/powershell \
    && pip install apprise \
    && mkdir -p /config \
    && chmod 755 /config \
    && chown -R nobody:nogroup /config && chmod -R 777 /config \
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
