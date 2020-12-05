//
//  UserKeys.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2019/8/3.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation

@objcMembers
class UserKeys: NSObject {
    public static let ShadowsocksXOn = "ShadowsocksXOn"
    public static let ShadowsocksXRunningMode = "ShadowsocksXRunningMode"
    public static let Socks5_ListenAddress = "Socks5.ListenAddress"
    public static let Socks5_ListenPort = "Socks5.ListenPort"
    public static let ListenAddress = "ListenAddress"
    public static let Socks5_Timeout = "Socks5.Timeout"
    public static let Socks5_EnableUDPRelay = "Socks5.EnableUDPRelay"
    public static let Socks5_EnableVerboseMode = "Socks5.EnableVerboseMode"
    public static let HTTP_ListenAddress = "HTTP.ListenAddress"
    public static let HTTP_ListenPort = "HTTP.ListenPort"
    public static let HTTPOn = "HTTPOn"
    public static let FollowGlobal = "FollowGlobal"
    public static let ShowSpeed = "ShowSpeed"
    public static let LaunchAtLogin = "LaunchAtLogin"
    public static let Language = "Language"
    
    public static let ActiveServerProfile = "ActiveServerProfile"
    public static let ServerGroups = "ServerGroups"
    
    public static let LoadbalancePort = "LoadbalancePort"
    public static let LoadbalanceGroup = "LoadbalanceGroup"
    public static let LoadbalanceProfiles = "LoadbalanceProfiles"
    public static let LoadbalanceEnableAllNodes = "LoadbalanceEnableAllNodes"
    public static let LoadbalanceStrategy = "LoadbalanceStrategy"
    
    public static let SSPrefix = "ss://"
    public static let SSRPrefix = "ssr://"
    
    public static let OrderAddress = "order.address"
    public static let OrderRemark = "order.remark"
    
    public static let DNSEnable = "DNSEnable"
    public static let DNSServers = "DNSServers"
    
    public static let RuleDefaultFlow = "rule.default.flow"
    public static let RuleConfigs = "rule.configs"
    
    public static let Mode_Manual = "manual"
    public static let Mode_Global = "global"
    public static let Mode_Rule = "rule"
    public static let Mode_Loadbalance = "loadbalance"
}
