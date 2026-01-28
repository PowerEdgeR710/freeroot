#!/bin/sh

ROOTFS_DIR="$(pwd)/rootfs"
RAM_DIR="$ROOTFS_DIR/ram"
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

case "$ARCH" in
  x86_64)
    ROOTFS_ARCH=amd64
    PROOT_ARCH=x86_64
    ;;
  aarch64)
    ROOTFS_ARCH=arm64
    PROOT_ARCH=aarch64
    ;;
  *)
    echo "Unsupported CPU architecture: ${ARCH}"
    exit 1
    ;;
esac

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$ROOTFS_DIR" "$RAM_DIR"

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    clear
    cat figlet
    echo "Version v1.0"
    echo " "
    echo -e "${BLUE}Which flavor do you want to install?${NC}"
    echo " "
    echo "1) Ubuntu 22.04"
    echo "2) Alpine"
    echo " "
    echo -e "${YELLOW}Enter number (1/2) ${NC}"
    read choice
    case $choice in
        1)
            INSTALL_FLAVOR=ubuntu
            ;;
        2)
            INSTALL_FLAVOR=alpine
            ;;
        *)
            echo "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
fi

export INSTALL_FLAVOR

case $INSTALL_FLAVOR in
    ubuntu)
        ROOTFS_URL_BASE="${ROOTFS_ARCH}.tar.gz"
        FLAV_PREFIX=""
        ;;
    alpine)
        ROOTFS_URL_BASE="alpine-${ROOTFS_ARCH}.tar.gz"
        FLAV_PREFIX="alpine-"
        ;;
esac

ROOTFS_TAR=""
for c in "./${FLAV_PREFIX}${ROOTFS_ARCH}.tar.gz" "./${FLAV_PREFIX}${PROOT_ARCH}.tar.gz" "./${ROOTFS_ARCH}.tar.gz" "./${PROOT_ARCH}.tar.gz"; do
    if [ -f "$c" ]; then
        ROOTFS_TAR="$(pwd)/$(basename "$c")"
        break
    fi
done

if [ -z "$ROOTFS_TAR" ]; then
    ROOTFS_TAR="$(pwd)/${ROOTFS_URL_BASE}"
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    if [ -f "$ROOTFS_TAR" ]; then
        echo -e "${GREEN}Found local rootfs file: $(basename "$ROOTFS_TAR").${NC}"
    else
        echo -e "${GREEN}Downloading ${INSTALL_FLAVOR} rootfs tarball...${NC}"
        ROOTFS_URL="https://github.com/poweredger710/umcroot/raw/refs/heads/v1.0/${ROOTFS_URL_BASE}"
        wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_TAR" "$ROOTFS_URL"
        if [ $? -ne 0 ] || [ ! -s "$ROOTFS_TAR" ]; then
            echo -e "${RED}Download failed or file is empty. Exiting.${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}Extracting rootfs into ${ROOTFS_DIR}...${NC}"
    tar -xf "$ROOTFS_TAR" -C "$ROOTFS_DIR" || { echo -e "${RED}Extraction failed. Exiting.${NC}"; exit 1; }
fi

PROOT_BIN=""
if [ -f "$(pwd)/proot-${PROOT_ARCH}" ]; then
    PROOT_BIN="$(pwd)/proot-${PROOT_ARCH}"
elif [ -f "$(pwd)/proot" ]; then
    PROOT_BIN="$(pwd)/proot"
fi

if [ -z "$PROOT_BIN" ]; then
    PROOT_BIN="$(pwd)/proot-${PROOT_ARCH}"
    echo -e "${GREEN}Downloading proot binary...${NC}"
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$PROOT_BIN" "https://raw.githubusercontent.com/poweredger710/umcroot/v1.0/proot-${PROOT_ARCH}"
    if [ $? -ne 0 ] || [ ! -s "$PROOT_BIN" ]; then
        echo -e "${RED}proot download failed. Exiting.${NC}"
        exit 1
    fi
fi

chmod +x "$PROOT_BIN"

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
    echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "$ROOTFS_DIR/etc/resolv.conf"
    if [ "$INSTALL_FLAVOR" = "ubuntu" ]; then
        echo "deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse" > $ROOTFS_DIR/etc/apt/sources.list
        echo "deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse" >> $ROOTFS_DIR/etc/apt/sources.list
        echo "deb http://archive.ubuntu.com/ubuntu jammy-security main restricted universe multiverse" >> $ROOTFS_DIR/etc/apt/sources.list
    fi
    touch "$ROOTFS_DIR/.installed"
fi

if [ ! -f "$ROOTFS_DIR/init" ] && [ -f "$(pwd)/init" ]; then
    echo -e "${GREEN}Copying init script into rootfs...${NC}"
    cp "$(pwd)/init" "$ROOTFS_DIR/init"
    chmod +x "$ROOTFS_DIR/init"
fi

"$PROOT_BIN" --rootfs="$ROOTFS_DIR" -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /init
