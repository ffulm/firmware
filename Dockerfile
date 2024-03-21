FROM debian:11
RUN apt-get update; \
  apt-get install --no-install-recommends -y subversion g++ zlib1g-dev build-essential git python time libncurses5-dev gawk gettext unzip file libssl-dev wget; \
  apt-get install --no-install-recommends -y ca-certificates; \
  apt-get clean; \
  rm -vrf /var/lib/apt/lists/*

ENV FORCE_UNSAFE_CONFIGURE=1
RUN \
  git clone https://git.openwrt.org/openwrt/openwrt.git; \
  cd openwrt; \
  git reset --hard 6fc02f2a45e151ce16677d6131251af86ab4fc06; \
  \
  git clone -b v2.3.1 https://github.com/ffulm/firmware.git; \
  cp -rf firmware/files firmware/package firmware/feeds.conf .; \
  \
  ./scripts/feeds update -a; \
  ./scripts/feeds install -a; \
  \
  git am --whitespace=nowarn firmware/patches/openwrt/*.patch; \
  \
  cd feeds/routing; \
  git am --whitespace=nowarn ../../firmware/patches/routing/*.patch; \
  cd ../../; \
  \
  cd feeds/packages; \
  git am --whitespace=nowarn ../../firmware/patches/packages/*.patch; \
  cd ../../; \
  \
  rm -rf firmware tmp;
