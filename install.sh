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
    echo "Error: running script on unsupported platform"
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
        echo "Downloading: $url"
        curl -s -O --output-dir $VERSION_NUM_FULL $url
    done

}

function verify_bitcoin_core {

    echo "Downloading: builder-keys"
    if [ ! -d $KEYS_REPO ]; then
        git clone $KEYS_REPO_URL 2> $LOG_FILE
    else
        git -C $KEYS_REPO pull 2> $LOG_FILE
    fi
    
    echo "Importing: builder-keys"
    gpg --import $KEYS_DIR/* 2> $LOG_FILE
    gpg --keyserver hkps://keys.openpgp.org --refresh-keys 2> $LOG_FILE

    echo "Verifying: hashes and signatures"
    cd $VERSION_NUM_FULL
    shasum -a 256 --ignore-missing --check SHA256SUMS 2> $LOG_FILE
    gpg --verify SHA256SUMS.asc 2> $LOG_FILE
}

function install_bitcoin_core {
    echo "Installing: $VERSION_NUM_FULL"
    tar xzf *.tar.gz

    if [ $PLATFORM_NAME == "linux-gnu"]; then
        sudo install -m 0755 -o root -g root -t /usr/local/bin bin/*
    elif [ $PLATFORM_NAME == "apple-darwin" ]; then
        if [ ! -d /usr/local/bin ]; then
            sudo mkdir -p /usr/local/bin
        fi
        sudo cp bin/bitcoin* /usr/local/bin/.
    fi
}


download_bitcoin_core
verify_bitcoin_core
install_bitcoin_core
