#
# Build image for the MT7981B driver porting pipeline.
# Ubuntu 22.04 is the distro the OpenWrt 23.05 build deps are documented for.
#
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    OPENWRT_BRANCH=openwrt-24.10 \
    OPENWRT_TARGET=mediatek \
    OPENWRT_SUBTARGET=filogic \
    OPENWRT_SRC=/build/openwrt \
    JOBS=8

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
        gettext git libncurses5-dev libssl-dev python3 python3-setuptools \
        python3-pip rsync swig unzip zlib1g-dev file wget curl \
        ca-certificates xxd jq less \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY scripts/      /build/scripts/
COPY package/      /build/package/
COPY patches/      /build/patches/

# Normalise line endings for the shell entry points, otherwise a Windows
# checkout gives "/bin/bash^M: bad interpreter".
RUN sed -i 's/\r$//' /build/scripts/*.sh \
    && chmod +x /build/scripts/*.sh

ENTRYPOINT ["/build/scripts/run-pipeline.sh"]
