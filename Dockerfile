FROM docker.io/library/python:3.13-alpine

ARG TARGETARCH
ARG VENDOR
ARG VERSION

ENV UMASK="0002" \
    TZ="Europe/Berlin" \
    POWERSHELL_DISTRIBUTION_CHANNEL="PSDocker" \
    PosterizarrNonRoot="TRUE"

RUN apk add --no-cache \
        catatonit \
        curl \
        imagemagick  \
        imagemagick-heic \
        imagemagick-jpeg \
        libjpeg-turbo \
        powershell \
        tzdata \
    && pwsh -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
        Install-Module -Name FanartTvAPI -Scope AllUsers -Force" \
    && chmod -R 755 /usr/local/share/powershell \
    && pip install apprise \
    && mkdir -p /config \
    && chmod 755 /config \
    && chown -R nobody:nogroup /config && chmod -R 777 /config \
    && mkdir -p /.local/share/powershell/PSReadLine && \
    chown -R nobody:nogroup /.local && \
    chmod -R 777 /.local

# Copy application files
COPY entrypoint.sh /entrypoint.sh
COPY Start.ps1 /Start.ps1
COPY donate.txt /donate.txt

# Fix file permissions in a single RUN command
RUN chmod +x /entrypoint.sh \
    && chown nobody:nogroup /entrypoint.sh

USER nobody:nogroup

WORKDIR /config

VOLUME ["/config"]

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/fscorrupt/Posterizarr"
LABEL org.opencontainers.image.description="Posterizarr - Automated poster generation for Plex/Jellyfin/Emby media libraries"
LABEL org.opencontainers.image.licenses="GPL-3.0"
