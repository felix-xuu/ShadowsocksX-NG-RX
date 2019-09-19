#!/bin/sh

#  install_haproxy.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix on 2019/8/16.
#  Copyright © 2019 felix.xu. All rights reserved.
set -e

cd `dirname "${BASH_SOURCE[0]}"`
haproxyVersion=2.0.6
mkdir -p "$HOME/Library/Application Support/ShadowsocksX-NG-RX/haproxy-$haproxyVersion"
cp -f haproxy "$HOME/Library/Application Support/ShadowsocksX-NG-RX/haproxy-$haproxyVersion/"
rm -f "$HOME/Library/Application Support/ShadowsocksX-NG-RX/haproxy"
ln -s "$HOME/Library/Application Support/ShadowsocksX-NG-RX/haproxy-$haproxyVersion/haproxy" "$HOME/Library/Application Support/ShadowsocksX-NG-RX/haproxy"
