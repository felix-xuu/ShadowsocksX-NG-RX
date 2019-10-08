#!/bin/sh

#  install_helper.sh
#  shadowsocks
#
#  Created by clowwindy on 14-3-15.
set -e

cd `dirname "${BASH_SOURCE[0]}"`
sudo mkdir -p "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
sudo cp proxy_conf_helper "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
sudo chown root:admin "$HOME/Library/Application Support/ShadowsocksX-NG-RX/proxy_conf_helper"
sudo chmod +s "$HOME/Library/Application Support/ShadowsocksX-NG-RX/proxy_conf_helper"
