FROM mcr.microsoft.com/powershell:7.4-alpine-3.17
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source https://github.com/fscorrupt/docker-posterizarr
RUN apk update
RUN apk add --no-cache \
    python3 \
    py3-pip \
    imagemagick \
    tini
RUN pip3 install apprise
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease"
RUN mkdir /config
COPY Start.ps1 .
ENTRYPOINT ["/sbin/tini", "-s", "pwsh", "Start.ps1", "--"]
