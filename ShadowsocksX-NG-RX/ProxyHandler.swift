//
//  ProxyHandler.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2020/7/18.
//  Copyright © 2020 felix.xu. All rights reserved.
//

import Foundation

func enableGlobalProxy() {
    disableProxy()
    let defaults = UserDefaults.standard
    proxyControl(aim: "-setsocksfirewallproxy", args: ["127.0.0.1", defaults.string(forKey: UserKeys.Socks5_ListenPort)!].joined(separator: " "))
    if defaults.bool(forKey: UserKeys.HTTPOn) && defaults.bool(forKey: UserKeys.HTTP_FollowGlobal) {
        proxyControl(aim: "-setsecurewebproxy", args: ["127.0.0.1", defaults.string(forKey: UserKeys.HTTP_ListenPort)!].joined(separator: " "))
        proxyControl(aim: "-setwebproxy", args: ["127.0.0.1", defaults.string(forKey: UserKeys.HTTP_ListenPort)!].joined(separator: " "))
    }
}

func disableProxy() {
    proxyControl(aim: "-setautoproxystate", args: "off")
    proxyControl(aim: "-setwebproxystate", args: "off")
    proxyControl(aim: "-setsecurewebproxystate", args: "off")
    proxyControl(aim: "-setsocksfirewallproxystate", args: "off")
}

func setPassby() {
    let hosts = ["0.0.0.0/8","10.0.0.0/8","100.64.0.0/10","127.0.0.0/8","169.254.0.0/16","172.16.0.0/12","192.0.0.0/24","192.0.2.0/24","192.88.99.0/24","192.168.0.0/16","198.18.0.0/15","198.51.100.0/24","203.0.113.0/24","224.0.0.0/4","240.0.0.0/4","255.255.255.255/32","::1/128","fc00::/7","fe80::/10"]
    proxyControl(aim: "-setproxybypassdomains", args: hosts.joined(separator: " "))
}

func proxyControl(aim: String, args: String) {
    let shPath = Bundle.main.path(forResource: "networksetup", ofType: "sh")
    let task = Process.launchedProcess(launchPath: shPath!, arguments: [aim, args])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("proxy changed successful:\(aim)")
    } else {
        NSLog("proxy change failed:\(aim)")
    }
}

func applyConfig() {
    let defaults = UserDefaults.standard
    let isOn = defaults.bool(forKey: UserKeys.ShadowsocksXOn)
    let mode = defaults.string(forKey: UserKeys.ShadowsocksXRunningMode)
    if isOn {
        if mode == "global" {
            if ServerProfileManager.activeProfile != nil {
                writeSSLocalConfFile(ServerProfileManager.activeProfile!.toJsonConfig())
                ReloadConfSSLocal()
                if defaults.bool(forKey: UserKeys.HTTPOn) {
                    ReloadConfPrivoxy()
                } else {
                    StopPrivoxy()
                }
            }
            enableGlobalProxy()
        } else if mode == "manual" {
            if ServerProfileManager.activeProfile != nil {
                writeSSLocalConfFile(ServerProfileManager.activeProfile!.toJsonConfig())
                ReloadConfSSLocal()
                if defaults.bool(forKey: UserKeys.HTTPOn) {
                    ReloadConfPrivoxy()
                } else {
                    StopPrivoxy()
                }
            }
            disableProxy()
        } else if mode == "rule" {
            RuleManager.syncRuleFlow()
        } else if mode == "loadbalance" {
            enableLoadbalance()
        }
    } else {
        disableProxy()
        StopHaproxy()
        StopPrivoxy()
        StopSSLocal()
    }
}

func enableLoadbalance() {
    if LoadBalance.getLoadBalanceGroup() == nil {
        let alert = NSAlert.init()
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK".localized)
        alert.messageText = "Warning".localized
        alert.informativeText = "Config your load balance preference firstly please".localized
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
        return
    }
    LoadBalance.enableLoadBalance()
}
