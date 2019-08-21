#!/bin/sh

#  reload_conf_haproxy.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix on 2019/8/16.
#  Copyright © 2019 felix.xu. All rights reserved.

launchctl unload "$HOME/Library/LaunchAgents/com.felix.xu.ShadowsocksX-NG-RX.loadbalance.plist"
launchctl load "$HOME/Library/LaunchAgents/com.felix.xu.ShadowsocksX-NG-RX.loadbalance.plist"
