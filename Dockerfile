FROM docker.io/library/python:3.13-alpine

ARG TARGETARCH
ARG VENDOR
ARG VERSION

ENV UMASK="0002" \
    TZ="Europe/Berlin" \
    POWERSHELL_DISTRIBUTION_CHANNEL="PSDocker" \
    PosterizarrNonRoot="TRUE" \
    PSModuleAnalysisCacheEnabled="false" \
    PSModuleAnalysisCachePath=""

# Install packages, create directories, copy files, and set permissions in a single RUN command to reduce layers
RUN echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
    && echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories \
    && apk upgrade --update-cache --available \
    && apk update \
    && apk add --no-cache \
        curl \
        imagemagick@edge \
        imagemagick-libs@edge \
        imagemagick-heic@edge \
        imagemagick-jpeg@edge \
        libjpeg-turbo-dev@edge \
        powershell \
        tzdata \
        pango \
        cairo \
        fribidi \
        harfbuzz \
        ttf-dejavu \
        ttf-freefont \
    && pwsh -NoProfile -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
        Install-Module -Name FanartTvAPI -Scope AllUsers -Force" \
    && chmod -R 755 /usr/local/share/powershell \
    && pip install apprise \
    && mkdir -p /app && chmod -R 755 /app \
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
