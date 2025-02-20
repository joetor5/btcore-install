# bitcoin-core-install

Install script for Bitcoin Core (https://bitcoincore.org/).

Works on macOS and GNU/Linux systems.

## Prerequisites

* Git
* cURL
* GnuPG
* OpenSSL


## Usage

```
git clone https://github.com/joetor5/bitcoin-core-install.git
cd bitcoin-core-install
chmod +x install.sh
./install
```

The latest Bitcoin Core version will get installed by default. Optionally, a version number can be passed as an argument:

```
./install 28.1
```
