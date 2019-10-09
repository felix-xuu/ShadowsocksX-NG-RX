#!/bin/sh

#  reload_conf.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix on 2019/8/16.
#  Copyright © 2019 felix.xu. All rights reserved.

launchctl unload "$HOME/Library/LaunchAgents/$1"
launchctl load "$HOME/Library/LaunchAgents/$1"
