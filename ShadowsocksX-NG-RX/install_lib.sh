#!/bin/sh

#  install_lib.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix Xu on 2020/1/16.
#  Copyright © 2020 felix.xu. All rights reserved.
set -e

cd `dirname "${BASH_SOURCE[0]}"`

cp -f libev.4.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libcares.2.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libmbedcrypto.3.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libsodium.23.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libpcre.1.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libmbedcrypto.2.16.2.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libmbedcrypto.2.24.0.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libmbedcrypto.5.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libmbedcrypto.2.25.0.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
cp -f libmbedcrypto.6.dylib "$HOME/Library/Application Support/ShadowsocksX-NG-RX/"
