#!/usr/bin/env bash
# Copyright (c) 2025 Joel Torres
# Distributed under the MIT License. See the accompanying file LICENSE.

BTCORE_INSTALL_NAME="btcore-install"
BTCORE_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/joetor5/btcore-install/develop/btcore-install.sh"
BTCORE_INSTALL_VERSION_URL="https://raw.githubusercontent.com/joetor5/btcore-install/develop/.script_version"
BTCORE_INSTALL_HOME="$HOME/.$BTCORE_INSTALL_NAME"
BTCORE_INSTALL_BIN="$BTCORE_INSTALL_HOME/bin"
BTCORE_INSTALL_SCRIPT="$BTCORE_INSTALL_BIN/$BTCORE_INSTALL_NAME"

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

    shell_rc_files=(~/.zshrc ~/.bashrc)
    for rc_file in "${shell_rc_files[@]}"
    do
        if [[ -f $rc_file ]]; then
            if [[ $(cat $rc_file | grep "$BTCORE_INSTALL_NAME" >/dev/null 2>&1; echo $?) != 0 ]]; then
                echo 'export PATH="$PATH:$HOME/.btcore-install/bin"' >> $rc_file
            fi
        fi
    done


}

check_latest_btcore_install_version () {

    if [[ -f $BTCORE_INSTALL_SCRIPT ]]; then
        latest_version=$(curl -sSL $BTCORE_INSTALL_VERSION_URL)
        installed_version=$($BTCORE_INSTALL_SCRIPT -v)
        if [[ $latest_version == $installed_version  ]]; then
            echo "Latest version ($latest_version) installed, nothing to update."
            exit 0
        fi
    fi
}

download_btcore_install () {

    echo "Downloading and installing $BTCORE_INSTALL_NAME..."
    curl -sSL -o $BTCORE_INSTALL_NAME --output-dir $BTCORE_INSTALL_BIN $BTCORE_INSTALL_SCRIPT_URL && \
    chmod +x $BTCORE_INSTALL_BIN/$BTCORE_INSTALL_NAME
    exit_if_error "unable to install $BTCORE_INSTALL_NAME"
    
    echo -e "\033[32;1mSuccess!\033[0m"
}


install () {
    setup_btcore_install_home
    check_latest_btcore_install_version
    download_btcore_install
}

install
