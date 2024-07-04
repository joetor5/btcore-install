#!/bin/bash
# Copyright (c) 2024 Joel Torres
# Distributed under the MIT software license, see the accompanying
# file LICENSE or https://opensource.org/license/mit.


BITCOIN_CORE_URL="https://bitcoincore.org"
BIN_URL="$BITCOIN_CORE_URL/bin"
DOWNLOAD_URL="$BITCOIN_CORE_URL/en/download/"
VERSION_NUM=$(curl -s $DOWNLOAD_URL | grep "Latest version" | sed 's/.*Latest version: \([0-9]*\.[0-9]*\).*/\1/')
VERSION_NUM_FULL="bitcoin-core-$VERSION_NUM"

KEYS_REPO="guix.sigs"
KEYS_REPO_URL="https://github.com/bitcoin-core/$KEYS_REPO"
KEYS_DIR="$KEYS_REPO/builder-keys"

LOG_FILE="$(pwd)/log"

PLATFORM_ARCH=$(uname -m)
if [ $(uname) == "Darwin" ]; then
    PLATFORM_NAME="apple-darwin"
elif [ $(uname) == "Linux" ]; then
    PLATFORM_NAME="linux-gnu"
else
    echo -e "\033[31;1mInstallation aborted: running script on unsupported platform\033[0m"
    exit 1
fi

function download_bitcoin_core {
    file_download_url="$BIN_URL/$VERSION_NUM_FULL/bitcoin-$VERSION_NUM-$PLATFORM_ARCH-$PLATFORM_NAME.tar.gz"
    bin_hash_url="$BIN_URL/$VERSION_NUM_FULL/SHA256SUMS"
    hash_sign_url="$bin_hash_url.asc"
    
    if [ ! -d $VERSION_NUM_FULL ]; then
        mkdir $VERSION_NUM_FULL
    fi

    for url in $file_download_url $bin_hash_url $hash_sign_url
    do
        echo -e "\033[1m==> Downloading $url\033[0m"
        curl -O --output-dir $VERSION_NUM_FULL $url
    done

}

function verify_bitcoin_core {

    if [ ! -d $KEYS_REPO ]; then
        echo -e "\033[1m==> Downloading builder-keys ($KEYS_REPO_URL)\033[0m"
        git clone $KEYS_REPO_URL
    else
        echo -e "\033[1m==> Updating builder-keys\033[0m"
        git -C $KEYS_REPO pull
    fi
    
    echo -e "\033[1m==> Importing and refreshing keys\033[0m"
    gpg --import $KEYS_DIR/*
    gpg --keyserver hkps://keys.openpgp.org --refresh-keys

    echo -e "\033[1m==> Verifying hashes and signatures\033[0m"
    cd $VERSION_NUM_FULL
    shasum -a 256 --ignore-missing --check SHA256SUMS
    if [ $? != 0 ]; then
        echo -e "\033[31;1mInstallation aborted: failure on computing hashes\033[0m"
        exit 1
    fi

    touch .hash_verified
    gpg --verify SHA256SUMS.asc 2> >(grep "Good signature")
    echo
    while true; do
        read -p "The above good signatures were found. Do you trust some of these? [y/n]: " answer
        case $answer in
            Y|y)
                touch .sign_verified; break;;
            N|n)
                echo -e "\033[31;1mInstallation aborted: keys not trusted\033[0m"; exit 1;;
        esac
    done

    cd ..
}

function install_bitcoin_core {
    echo -e "\033[1m==> Installing $VERSION_NUM_FULL\033[0m"
    cd $VERSION_NUM_FULL
    tar xzf *.tar.gz

    if [ $PLATFORM_NAME == "linux-gnu" ]; then
        sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-$VERSION_NUM/bin/*
    elif [ $PLATFORM_NAME == "apple-darwin" ]; then
        if [ ! -d /usr/local/bin ]; then
            sudo mkdir -p /usr/local/bin
        fi
        sudo cp bitcoin-$VERSION_NUM/bin/bitcoin* /usr/local/bin/.
    fi

    touch .installed

    cd ..
}


if [ ! -e $VERSION_NUM_FULL/.hash_verified ]; then
    download_bitcoin_core
fi

if [ ! -e $VERSION_NUM_FULL/.sign_verified ]; then
    verify_bitcoin_core
fi

if [ ! -e $VERSION_NUM_FULL/.installed ]; then
    install_bitcoin_core
fi
