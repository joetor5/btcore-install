#!/usr/bin/env bash
# Copyright (c) 2025 Joel Torres
# Distributed under the MIT License. See the accompanying file LICENSE.

BTCORE_INSTALL_NAME="btcore-install"
BTCORE_INSTALL_URL="https://raw.githubusercontent.com/joetor5/btcore-install/develop/btcore-install.sh"
BTCORE_INSTALL_HOME="$HOME/.$BTCORE_INSTALL_NAME"
BTCORE_INSTALL_BIN="$BTCORE_INSTALL_HOME/bin"

exit_if_error () {
    if [[ $? != 0 ]]; then
        echo -e "\033[31;1mError: $1\033[0m"
        exit 1
    fi
}

setup_btcore_install_home () {
    
    if [[ ! -d "$BTCORE_INSTALL_HOME" ]]; then
        echo "Setting up $BTCORE_INSTALL_NAME home..."
        mkdir -p $BTCORE_INSTALL_BIN
        exit_if_error "unable to create directories at $BTCORE_INSTALL_HOME"
    fi

}

download_btcore_install () {

    echo "Downloading and installing $BTCORE_INSTALL_NAME..."
    curl -sSL -o $BTCORE_INSTALL_NAME --output-dir $BTCORE_INSTALL_BIN $BTCORE_INSTALL_URL && \
    chmod +x $BTCORE_INSTALL_BIN/$BTCORE_INSTALL_NAME
    exit_if_error "unable to install $BTCORE_INSTALL_NAME"
    
    echo -e "\033[32;1mSuccess!\033[0m"
}


install () {
    setup_btcore_install_home
    download_btcore_install
}

install
