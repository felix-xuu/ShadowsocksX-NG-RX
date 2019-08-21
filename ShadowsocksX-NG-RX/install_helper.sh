#!/bin/sh

#  install_helper.sh
#  shadowsocks
#
#  Created by clowwindy on 14-3-15.
set -e

cd `dirname "${BASH_SOURCE[0]}"`
sudo mkdir -p "/Library/Application Support/ShadowsocksX-NG-RX/"
sudo cp proxy_conf_helper "/Library/Application Support/ShadowsocksX-NG-RX/"
sudo chown root:admin "/Library/Application Support/ShadowsocksX-NG-RX/proxy_conf_helper"
sudo chmod +s "/Library/Application Support/ShadowsocksX-NG-RX/proxy_conf_helper"
