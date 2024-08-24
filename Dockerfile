# Base Image
# https://mcr.microsoft.com/v2/powershell/tags/list
# Imagemagick 7.1.1.36
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr

# Update the package list and install dependencies
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        python3 \
        python3-pip \
        tini \
        docker.io \
        wget \
        unzip \
        autoconf \
        pkg-config \
        build-essential \
        curl \
        libpng-dev \
    && apt-get clean

RUN wget https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.1-36.tar.gz && \
    tar xzf 7.1.1-36.tar.gz && \
    rm 7.1.1-36.tar.gz && \
    apt-get clean && \
    apt-get autoremove

RUN sh ./ImageMagick-7.1.1-36/configure --prefix=/usr/local --with-bzlib=yes --with-fontconfig=yes --with-freetype=yes --with-gslib=yes --with-gvc=yes --with-jpeg=yes --with-jp2=yes --with-png=yes --with-tiff=yes --with-xml=yes --with-gs-font-dir=yes && \
    make -j && make install && ldconfig /usr/local/lib/

# Install Python library
RUN pip3 install apprise

# Install PowerShell module
RUN pwsh -c "Install-Module FanartTvAPI -Force -SkipPublisherCheck -AllowPrerelease"

# Create a directory
RUN mkdir /config

# Copy the PowerShell script into the container
COPY Start.ps1 .

# Set the entrypoint
ENTRYPOINT ["/usr/bin/tini", "-s", "pwsh", "Start.ps1", "--"]
