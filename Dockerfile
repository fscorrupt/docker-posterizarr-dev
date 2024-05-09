# Base Image
FROM mcr.microsoft.com/powershell:7.4-alpine-3.17

# Labels
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source https://github.com/fscorrupt/docker-posterizarr

# Install build tools and libraries
RUN apk update && apk add --no-cache \
    alpine-sdk \
    autoconf \
    automake \
    libtool \
    gcc \
    g++ \
    make \
    pkgconfig \
    git \
    imagemagick-dev \
    libpng-dev \
    jpeg-dev \
    openjpeg-dev \
    lcms2-dev \
    libxml2-dev \
    freetype-dev \
    fontconfig-dev \
    perl \
    tiff-dev \
    webp-dev \
    zlib-dev

# Clone the ImageMagick repository
RUN git clone https://github.com/ImageMagick/ImageMagick.git /tmp/ImageMagick \
    && cd /tmp/ImageMagick \
    && git checkout `git describe --tags $(git rev-list --tags --max-count=1)` \
    && ./configure \
        --with-modules \
        --enable-shared \
        --disable-static \
        --with-perl \
        --with-gslib \
        --with-webp \
        --with-openjp2 \
    && make -j$(nproc) \
    && make install \
    && ldconfig /usr/local/lib

# Clean up unnecessary packages and files
RUN apk del alpine-sdk autoconf automake libtool gcc g++ make git \
    && rm -rf /var/cache/apk/* /tmp/ImageMagick

# Install other necessary packages
RUN apk add --no-cache \
    python3 \
    py3-pip \
    tini \
    docker-cli

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
