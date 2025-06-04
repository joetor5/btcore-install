# btcore-install

Install script for Bitcoin Core (https://bitcoincore.org/).

Works on macOS and GNU/Linux systems.

## Prerequisites

* Git
* cURL
* GnuPG
* OpenSSL

## Install
```
curl -sSL https://raw.githubusercontent.com/joetor5/btcore-install/develop/install.sh | bash
```

This will install or update the btcore-install script.

## Usage

To begin the Bitcoin Core installation, simply run:

```
btcore-install
```

The latest Bitcoin Core version will get installed by default. Optionally, a version number can be passed as an argument:

```
btcore-install 28.1
```

## License

Distributed under the MIT License. See the accompanying file LICENSE.
