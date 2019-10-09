#!/bin/sh

#  stop.sh
#  ShadowsocksX-NG-RX
#
#  Created by Felix on 2019/8/16.
#  Copyright © 2019 felix.xu. All rights reserved.

launchctl unload "$HOME/Library/LaunchAgents/$1"
