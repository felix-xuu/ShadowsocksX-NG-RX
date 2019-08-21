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
    public static let Socks5_ListenPort = "Socks5.ListenPort"
    public static let ListenAddress = "ListenAddress"
    public static let PacServer_ListenAddress = "PacServer.ListenAddress"
    public static let PacServer_ListenPort = "PacServer.ListenPort"
    public static let Socks5_Timeout = "Socks5.Timeout"
    public static let Socks5_EnableUDPRelay = "Socks5.EnableUDPRelay"
    public static let Socks5_EnableVerboseMode = "Socks5.EnableVerboseMode"
    public static let GFWListURL = "GFWListURL"
    public static let ACLWhiteListURL = "ACLWhiteListURL"
    public static let ACLAutoListURL = "ACLAutoListURL"
    public static let ACLProxyBlockCHNURL = "ACLProxyBlockCHNURL"
    public static let AutoConfigureNetworkServices = "AutoConfigureNetworkServices"
    public static let HTTP_ListenPort = "HTTP.ListenPort"
    public static let HTTPOn = "HTTPOn"
    public static let HTTP_FollowGlobal = "HTTP.FollowGlobal"
    public static let ACLFileName = "ACLFileName"
    public static let AutoUpdateSubscribe = "AutoUpdateSubscribe"
    public static let ShowSpeed = "ShowSpeed"
    public static let LaunchAtLogin = "LaunchAtLogin"
    public static let Language = "Language"
    
    public static let ActiveServerProfile = "ActiveServerProfile"
    public static let ServerGroups = "ServerGroups"
    
    public static let Proxy4NetworkServices = "Proxy4NetworkServices"
    public static let LoadbalancePort = "LoadbalancePort"
    public static let EnableLoadbalance = "EnableLoadbalance"
    public static let LoadbalanceGroup = "LoadbalanceGroup"
    public static let LoadbalanceProfiles = "LoadbalanceProfiles"
    public static let LoadbalanceEnableAllNodes = "LoadbalanceEnableAllNodes"
    public static let LoadbalanceStrategy = "LoadbalanceStrategy"
}
