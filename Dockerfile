# Base Image
# https://mcr.microsoft.com/v2/powershell/tags/list
# Imagemagick 7.1.1.36
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source=https://github.com/fscorrupt/docker-posterizarr

# Set environment variables
ENV IMAGEMAGICK_VERSION=7.1.1-36
ENV IMAGEMAGICK_DIR=/usr/local
ENV PATH="$IMAGEMAGICK_DIR/bin:$PATH"

# Update the package list and install dependencies
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
        software-properties-common \
        python3 \
        python3-pip \
        tini \
        docker.io \
        wget \
        build-essential \
        autoconf \
        pkg-config \
        libpng-dev \
        libjpeg-dev \
        libtiff-dev \
        libgif-dev \
        libwebp-dev \
        libopenjp2-7-dev \
        librsvg2-dev \
        libde265-dev \
    && apt-get clean

# Install build dependencies for ImageMagick
RUN apt-get build-dep imagemagick -y

# Download and install ImageMagick from source
RUN wget https://www.imagemagick.org/download/ImageMagick.tar.gz -O /tmp/ImageMagick.tar.gz \
    && tar xzvf /tmp/ImageMagick.tar.gz -C /tmp/ \
    && cd /tmp/ImageMagick-* \
    && ./configure --enable-shared --with-modules --with-gslib \
    && make -j$(nproc) \
    && make install \
    && ldconfig /usr/local/lib \
    && rm -rf /tmp/ImageMagick*

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
