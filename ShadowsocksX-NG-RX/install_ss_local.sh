#!/bin/sh

#  install_ss_local.sh
#  ShadowsocksX-NG
#
#  Created by 邱宇舟 on 16/6/6.
#  Copyright © 2016年 qiuyuzhou. All rights reserved.
set -e

cd `dirname "${BASH_SOURCE[0]}"`
ssLocalVersion=3.3.1
mkdir -p "$HOME/Library/Application Support/ShadowsocksX-NG-RX/ss-local-$ssLocalVersion"
cp -f ss-local "$HOME/Library/Application Support/ShadowsocksX-NG-RX/ss-local-$ssLocalVersion/"
rm -f "$HOME/Library/Application Support/ShadowsocksX-NG-RX/ss-local"
ln -s "$HOME/Library/Application Support/ShadowsocksX-NG-RX/ss-local-$ssLocalVersion/ss-local" "$HOME/Library/Application Support/ShadowsocksX-NG-RX/ss-local"

cp -f libev.4.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libcares.2.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libmbedcrypto.3.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libsodium.23.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libpcre.1.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
