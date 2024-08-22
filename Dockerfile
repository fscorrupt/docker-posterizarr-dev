# Base Image
# https://mcr.microsoft.com/v2/powershell/tags/list
# Imagemagick 7.1.1.34
FROM mcr.microsoft.com/powershell:7.4-alpine-3.17

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr

# Add the Edge Community repository and update
RUN echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories \
    && echo @edge http://dl-cdn.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories \
    && apk upgrade --update-cache --available \
    && apk update \
    && apk add --no-cache \
        python3 \
        py3-pip \
        imagemagick-libs@edge \
        libjpeg-turbo-dev@edge \
        imagemagick@edge \
        tini \
        docker-cli \
        glibc-i18n \
        fontconfig \
        ttf-dejavu \
        ttf-droid \
        ttf-freefont \
        ttf-liberation \
        ttf-ubuntu-font-family

# Generate all locales, including RTL languages
RUN /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && /usr/glibc-compat/bin/localedef -i ar_EG -f UTF-8 ar_EG.UTF-8 \
    && /usr/glibc-compat/bin/localedef -i he_IL -f UTF-8 he_IL.UTF-8 \
    && /usr/glibc-compat/bin/localedef -i fa_IR -f UTF-8 fa_IR.UTF-8 \
    && /usr/glibc-compat/bin/localedef -i ur_PK -f UTF-8 ur_PK.UTF-8

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
