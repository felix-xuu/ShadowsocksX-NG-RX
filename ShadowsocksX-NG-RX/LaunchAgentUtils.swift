//
//  BGUtils.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation
import SwiftyJSON

let SS_LOCAL_VERSION = "3.3.1"
let PRIVOXY_VERSION = "3.0.28"
let HAPROXY_VERSION = "2.0.5"
let V2RAY_VERSION = "4.20.0"
let APP_SUPPORT_DIR = "/Library/Application Support/ShadowsocksX-NG-RX/"
let LAUNCH_AGENT_DIR = "/Library/LaunchAgents/"
let LAUNCH_AGENT_CONF_SSLOCAL_NAME = "com.felix.xu.shadowsocksX-NG-RX.local.plist"
let LAUNCH_AGENT_CONF_PRIVOXY_NAME = "com.felix.xu.shadowsocksX-NG-RX.http.plist"
let LAUNCH_AGENT_CONF_HAPROXY_NAME = "com.felix.xu.shadowsocksX-NG-RX.loadbalance.plist"
let LAUNCH_AGENT_CONF_V2RAY_NAME = "com.felix.xu.shadowsocksX-NG-RX.v2ray.plist"

func getFileSHA1Sum(_ filepath: String) -> String {
    if let data = try? Data(contentsOf: URL(fileURLWithPath: filepath)) {
        return data.sha1()
    }
    return ""
}

// Ref: https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
// Genarate the mac launch agent service plist

//  MARK: sslocal
func generateSSLocalLauchAgentPlist() {
    let sslocalPath = NSHomeDirectory() + APP_SUPPORT_DIR + "ss-local"
    let logFilePath = NSHomeDirectory() + "/Library/Logs/ssr-local.log"
    let launchAgentDirPath = NSHomeDirectory() + LAUNCH_AGENT_DIR
    let plistFilepath = launchAgentDirPath + LAUNCH_AGENT_CONF_SSLOCAL_NAME
    
    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        try! fileMgr.createDirectory(atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    let defaults = UserDefaults.standard
    let enableUdpRelay = defaults.bool(forKey: UserKeys.Socks5_EnableUDPRelay)
    let enableVerboseMode = defaults.bool(forKey: UserKeys.Socks5_EnableVerboseMode)
    let enabeledMode = defaults.string(forKey: UserKeys.ShadowsocksXRunningMode)
    
    var arguments = [sslocalPath, "-c", "ss-local-config.json", "--reuse-port", "--fast-open"]
    if enableUdpRelay {
        arguments.append("-u")
    }
    if enableVerboseMode {
        arguments.append("-v")
    }
    var ACLPath: String?
    if enabeledMode == "aclWhiteList" {
        ACLPath = NSHomeDirectory() + "/.ShadowsocksX-NG-RX/chn.acl"
    } else if enabeledMode == "aclAuto" {
        ACLPath = NSHomeDirectory() + "/.ShadowsocksX-NG-RX/gfwlist.acl"
    } else if enabeledMode == "aclBlockChina" {
        ACLPath = NSHomeDirectory() + "/.ShadowsocksX-NG-RX/blockchn.acl"
    }
    
    if ACLPath != nil {
        arguments.append("--acl")
        arguments.append(ACLPath!)
    }
    
    let dict: NSMutableDictionary = [
        "Label": "com.felix.xu.shadowsocksX-NG-RX.local",
        "WorkingDirectory": NSHomeDirectory() + APP_SUPPORT_DIR,
        "KeepAlive": true,
        "StandardOutPath": logFilePath,
        "StandardErrorPath": logFilePath,
        "ProgramArguments": arguments,
        "EnvironmentVariables": ["DYLD_LIBRARY_PATH": NSHomeDirectory() + APP_SUPPORT_DIR]
    ]
    dict.write(toFile: plistFilepath, atomically: true)
}

func ReloadConfSSLocal() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "reload_conf", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_SSLOCAL_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Reload ss-local succeeded.")
    } else {
        NSLog("Reload ss-local failed.")
    }
}

func StartSSLocal() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "start", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_SSLOCAL_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Start ss-local succeeded.")
    } else {
        NSLog("Start ss-local failed.")
    }
}

func StopSSLocal() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "stop", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_SSLOCAL_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Stop ss-local succeeded.")
    } else {
        NSLog("Stop ss-local failed.")
    }
}

func InstallSSLocal() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir + APP_SUPPORT_DIR
    if !fileMgr.fileExists(atPath: appSupportDir + "ss-local-\(SS_LOCAL_VERSION)/ss-local") {
        let installerPath = Bundle.main.path(forResource: "install", ofType: "sh")
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: ["ss-local", SS_LOCAL_VERSION])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Install ss-local succeeded.")
        } else {
            NSLog("Install ss-local failed.")
        }
    }
    generateSSLocalLauchAgentPlist()
}

func writeSSLocalConfFile(_ conf:[String:AnyObject]) {
    do {
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "ss-local-config.json"
        let data: Data = try JSONSerialization.data(withJSONObject: conf, options: .prettyPrinted)
        
        try data.write(to: URL(fileURLWithPath: filepath), options: .atomic)
        NSLog("Write ss-local file succeed.")
    } catch {
        NSLog("Write ss-local file failed.")
    }
}

func removeSSLocalConfFile() {
    let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "ss-local-config.json"
    try? FileManager.default.removeItem(atPath: filepath)
}

func SyncSSLocal() {
    if ServerProfileManager.activeProfile != nil && !ServerProfileManager.activeProfile!.URL().hasPrefix(UserKeys.VmessPrefix) {
        writeSSLocalConfFile((ServerProfileManager.activeProfile!.toJsonConfig()))
        let on = UserDefaults.standard.bool(forKey: UserKeys.ShadowsocksXOn)
        if on {
            ReloadConfSSLocal()
            SyncPac()
            SyncPrivoxy()
        }
    } else {
        removeSSLocalConfFile()
        StopSSLocal()
    }
}

func SyncV2ray() {
    if ServerProfileManager.activeProfile != nil && ServerProfileManager.activeProfile!.URL().hasPrefix(UserKeys.VmessPrefix) {
        writeV2rayConfFile(profiles: [ServerProfileManager.activeProfile!])
        let on = UserDefaults.standard.bool(forKey: UserKeys.ShadowsocksXOn)
        if on {
            ReloadConfV2ray()
            SyncPac()
            SyncPrivoxy()
        }
    } else {
        StopV2ray()
    }
}

//  MARK: privoxy
func generatePrivoxyLauchAgentPlist() {
    let privoxyPath = NSHomeDirectory() + APP_SUPPORT_DIR + "privoxy"
    let logFilePath = NSHomeDirectory() + "/Library/Logs/ssr-privoxy.log"
    let launchAgentDirPath = NSHomeDirectory() + LAUNCH_AGENT_DIR
    let plistFilepath = launchAgentDirPath + LAUNCH_AGENT_CONF_PRIVOXY_NAME
    
    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        try! fileMgr.createDirectory(atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    let arguments = [privoxyPath, "--no-daemon", "privoxy.config"]
    
    // For a complete listing of the keys, see the launchd.plist manual page.
    let dict: NSMutableDictionary = [
        "Label": "com.felix.xu.shadowsocksX-NG-RX.http",
        "WorkingDirectory": NSHomeDirectory() + APP_SUPPORT_DIR,
        "KeepAlive": true,
        "StandardOutPath": logFilePath,
        "StandardErrorPath": logFilePath,
        "ProgramArguments": arguments,
        "EnvironmentVariables": ["DYLD_LIBRARY_PATH": NSHomeDirectory() + APP_SUPPORT_DIR]
    ]
    dict.write(toFile: plistFilepath, atomically: true)
}

func ReloadConfPrivoxy() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "reload_conf", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_PRIVOXY_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Reload privoxy succeeded.")
    } else {
        NSLog("Reload privoxy failed.")
    }
}

func StartPrivoxy() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "start", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_PRIVOXY_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Start privoxy succeeded.")
    } else {
        NSLog("Start privoxy failed.")
    }
}

func StopPrivoxy() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "stop", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_PRIVOXY_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Stop privoxy succeeded.")
    } else {
        NSLog("Stop privoxy failed.")
    }
}

func InstallPrivoxy() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir+APP_SUPPORT_DIR
    if !fileMgr.fileExists(atPath: appSupportDir + "privoxy-\(PRIVOXY_VERSION)/privoxy") {
        let installerPath = Bundle.main.path(forResource: "install", ofType: "sh")
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: ["privoxy", PRIVOXY_VERSION])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Install privoxy succeeded.")
        } else {
            NSLog("Install privoxy failed.")
        }
    }
    generatePrivoxyLauchAgentPlist()
    writePrivoxyConfFile()
}

func writePrivoxyConfFile() {
    do {
        let defaults = UserDefaults.standard
        let bundle = Bundle.main
        let examplePath = bundle.path(forResource: "privoxy.config.example", ofType: nil)
        var example = try String(contentsOfFile: examplePath!, encoding: .utf8)
        example = example.replacingOccurrences(of: "{http}", with: defaults.string(forKey: UserKeys.HTTP_ListenAddress)! + ":" + String(defaults.integer(forKey: UserKeys.HTTP_ListenPort)))
        example = example.replacingOccurrences(of: "{socks5}", with: defaults.string(forKey: UserKeys.Socks5_ListenAddress)! + ":" + String(defaults.integer(forKey: UserKeys.Socks5_ListenPort)))
        let data = example.data(using: .utf8)
        
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "privoxy.config"
        
        try data?.write(to: URL(fileURLWithPath: filepath), options: .atomic)
    } catch {
        NSLog("Write privoxy file failed.")
    }
}

func removePrivoxyConfFile() {
    let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "privoxy.config"
    try? FileManager.default.removeItem(atPath: filepath)
}

func SyncPrivoxy() {
    writePrivoxyConfFile()

    let on = UserDefaults.standard.bool(forKey: UserKeys.HTTPOn)
    if on {
        ReloadConfPrivoxy()
    } else {
        removePrivoxyConfFile()
        StopPrivoxy()
    }
}

func generateHaproxyLauchAgentPlist() {
    let haproxyPath = NSHomeDirectory() + APP_SUPPORT_DIR + "haproxy"
    let logFilePath = NSHomeDirectory() + "/Library/Logs/ssr-haproxy.log"
    let launchAgentDirPath = NSHomeDirectory() + LAUNCH_AGENT_DIR
    let plistFilepath = launchAgentDirPath + LAUNCH_AGENT_CONF_HAPROXY_NAME
    
    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        try! fileMgr.createDirectory(atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    let arguments = [haproxyPath, "-dr", "-f", "haproxy.cfg"]
    
    // For a complete listing of the keys, see the launchd.plist manual page.
    let dict: NSMutableDictionary = [
        "Label": "com.felix.xu.shadowsocksX-NG-RX.loadbalance",
        "WorkingDirectory": NSHomeDirectory() + APP_SUPPORT_DIR,
        "KeepAlive": true,
        "StandardOutPath": logFilePath,
        "StandardErrorPath": logFilePath,
        "ProgramArguments": arguments
    ]
    dict.write(toFile: plistFilepath, atomically: true)
}

func ReloadConfHaproxy() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "reload_conf", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_HAPROXY_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Reload haproxy succeeded.")
    } else {
        NSLog("Reload haproxy failed.")
    }
}

func StartHaproxy() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "start", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_HAPROXY_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Start haproxy succeeded.")
    } else {
        NSLog("Start haproxy failed.")
    }
}

func StopHaproxy() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "stop", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_HAPROXY_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Stop haproxy succeeded.")
    } else {
        NSLog("Stop haproxy failed.")
    }
}

func InstallHaproxy() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir + APP_SUPPORT_DIR
    if !fileMgr.fileExists(atPath: appSupportDir + "haproxy-\(HAPROXY_VERSION)/haproxy") {
        let installerPath = Bundle.main.path(forResource: "install", ofType: "sh")
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: ["haproxy", HAPROXY_VERSION])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Install haproxy succeeded.")
        } else {
            NSLog("Install haproxy failed.")
        }
    }
    generateHaproxyLauchAgentPlist()
}

func writeHaproxyConfFile() {
    do {
        let defaults = UserDefaults.standard
        let bundle = Bundle.main
        let examplePath = bundle.path(forResource: "haproxy.cfg.example", ofType: nil)
        var example = try String(contentsOfFile: examplePath!, encoding: .utf8)
        example = example.replacingOccurrences(of: "{strategy}", with: defaults.string(forKey: UserKeys.LoadbalanceStrategy)!)
        example = example.replacingOccurrences(of: "{port}", with: defaults.string(forKey: UserKeys.LoadbalancePort)!)
        
        var data = example.data(using: .utf8)
        
        var profiles: [ServerProfile]
        if UserDefaults.standard.bool(forKey: UserKeys.LoadbalanceEnableAllNodes) {
            profiles = LoadBalance.getLoadBalanceGroup()!.serverProfiles
        } else {
            profiles = LoadBalance.getLoadBalanceProfiles()
        }
        var servers: String = ""
        for item in profiles {
            servers.append(contentsOf: "    server \(item.serverHost)-\(UUID().hashValue) \(item.serverHost):\(item.serverPort) check\n")
        }
        data?.append(contentsOf: servers.utf8)
        
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "haproxy.cfg"
        try data?.write(to: URL(fileURLWithPath: filepath), options: .atomic)
    } catch {
        NSLog("Write haproxy file failed.")
    }
}

func generateV2rayLauchAgentPlist() {
    let haproxyPath = NSHomeDirectory() + APP_SUPPORT_DIR + "v2ray"
    let logFilePath = NSHomeDirectory() + "/Library/Logs/ssr-v2ray.log"
    let launchAgentDirPath = NSHomeDirectory() + LAUNCH_AGENT_DIR
    let plistFilepath = launchAgentDirPath + LAUNCH_AGENT_CONF_V2RAY_NAME
    
    // Ensure launch agent directory is existed.
    let fileMgr = FileManager.default
    if !fileMgr.fileExists(atPath: launchAgentDirPath) {
        try! fileMgr.createDirectory(atPath: launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    let arguments = [haproxyPath, "-config", "v2ray.json"]
    
    // For a complete listing of the keys, see the launchd.plist manual page.
    let dict: NSMutableDictionary = [
        "Label": "com.felix.xu.shadowsocksX-NG-RX.v2ray",
        "WorkingDirectory": NSHomeDirectory() + APP_SUPPORT_DIR,
        "KeepAlive": true,
        "StandardOutPath": logFilePath,
        "StandardErrorPath": logFilePath,
        "ProgramArguments": arguments
    ]
    dict.write(toFile: plistFilepath, atomically: true)
}

func ReloadConfV2ray() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "reload_conf", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_V2RAY_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Reload v2ray succeeded.")
    } else {
        NSLog("Reload v2ray failed.")
    }
}

func StartV2ray() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "start", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_V2RAY_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Start v2ray succeeded.")
    } else {
        NSLog("Start v2ray failed.")
    }
}

func StopV2ray() {
    let bundle = Bundle.main
    let installerPath = bundle.path(forResource: "stop", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [LAUNCH_AGENT_CONF_V2RAY_NAME])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Stop v2ray succeeded.")
    } else {
        NSLog("Stop v2ray failed.")
    }
}

func InstallV2ray() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir + APP_SUPPORT_DIR
    if !fileMgr.fileExists(atPath: appSupportDir + "v2ray-\(V2RAY_VERSION)/v2ray") || !fileMgr.fileExists(atPath: appSupportDir + "v2ray-\(V2RAY_VERSION)/v2ctl") || !fileMgr.fileExists(atPath: appSupportDir + "geoip.dat") || !fileMgr.fileExists(atPath: appSupportDir + "geosite.dat") {
        let installerPath = Bundle.main.path(forResource: "install", ofType: "sh")
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: ["v2ray", V2RAY_VERSION])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Install v2ray succeeded.")
        } else {
            NSLog("Install v2ray failed.")
        }
    }
    generateV2rayLauchAgentPlist()
}

func writeV2rayConfFile(profiles: [ServerProfile]) {
    do {
        let defaults = UserDefaults.standard
        let bundle = Bundle.main
        let examplePath = bundle.path(forResource: "v2ray.json.example", ofType: nil)
        let example = try Data(contentsOf: URL(fileURLWithPath: examplePath!))
        var template = try JSON(data: example)
        
        template["inbounds"][0].dictionaryObject!["port"] = defaults.integer(forKey: UserKeys.Socks5_ListenPort)
        template["inbounds"][0].dictionaryObject!["listen"] = defaults.string(forKey: UserKeys.Socks5_ListenAddress)
        
        if profiles.count == 0 {
            return
        }

        let firstProfile = profiles[0]
        var outbounds = template["outbounds"].arrayValue
        var outbound = JSON()
        let net = firstProfile.net
        if net == "shadowsocks" {
            var ss = JSON()
            ss["email"] = JSON(firstProfile.remark + "@ss")
            ss["address"] = JSON(firstProfile.serverHost)
            ss["port"] = JSON(firstProfile.serverPort)
            ss["method"] = JSON(firstProfile.aid)
            ss["password"] = JSON(firstProfile.id)
            outbound["protocol"] = "shadowsocks"
            outbound["settings"] = JSON(["servers":[ss]])
        } else {
            outbound["protocol"] = "vmess"
            outbound["mux"] = JSON(["enabled":true])
            var vnexts = [JSON]()
            for profile in profiles {
                var vnext = JSON()
                vnext["address"] = JSON(profile.serverHost)
                vnext["port"] = JSON(profile.serverPort)
                var user = JSON()
                user["id"] = JSON(profile.id)
                user["alterId"] = JSON(Int(profile.aid) as Any)
                vnext["users"] = [user]
                vnexts.append(vnext)
            }
            outbound["settings"] = JSON(["vnext":vnexts])
            outbound["streamSettings"] = JSON(["network":firstProfile.net])
            if firstProfile.tls == "tls" {
                outbound["streamSettings"]["security"] = "tls"
                outbound["streamSettings"]["tlsSettings"] = ["allowInsecure":true]
            }
            if net == "kcp" || net == "mkcp" {
                var kcpSetting = JSON()
                kcpSetting["uplinkCapacity"] = 10
                kcpSetting["downlinkCapacity"] = 100
                kcpSetting["congestion"] = true
                kcpSetting["header"] = JSON(["type":firstProfile.type])
                outbound["streamSettings"]["kcpSettings"] = kcpSetting
            } else if net == "ws" {
                var wsSetting = JSON()
                wsSetting["path"] = JSON(firstProfile.path)
                wsSetting["headers"] = JSON(["Host":firstProfile.host])
                outbound["streamSettings"]["wsSettings"] = wsSetting
            } else if net == "h2" {
                var h2Setting = JSON()
                h2Setting["path"] = JSON(firstProfile.path)
                h2Setting["host"] = JSON(firstProfile.host)
                outbound["streamSettings"]["httpSettings"] = h2Setting
            } else if net == "quic" {
                var quic = JSON()
                quic["header"] = JSON(["type":firstProfile.type])
                quic["security"] = JSON(firstProfile.host)
                quic["key"] = JSON(firstProfile.path)
                outbound["streamSettings"]["quicSettings"] = quic
            } else if net == "tcp" {
                if firstProfile.type == "http" {
                    let headerPath = bundle.path(forResource: "v2rayheaders", ofType: "json")
                    let headerData = try Data(contentsOf: URL(fileURLWithPath: headerPath!))
                    var headers = try JSON(data: headerData)
                    headers["header"]["type"] = JSON(firstProfile.type)
                    if !firstProfile.host.isEmpty {
                        headers["header"]["request"]["headers"]["Host"] = JSON(firstProfile.host.components(separatedBy: ","))
                    }
                    if !firstProfile.path.isEmpty {
                        headers["header"]["request"]["path"] = [firstProfile.path]
                    }
                    outbound["streamSettings"]["tcpSettings"] = headers
                }
            }
        }
        outbound["tag"] = JSON(firstProfile.id)
        outbounds.append(outbound)
        template["outbounds"] = JSON(outbounds)
        
        var rules = template["routing"]["rules"].arrayValue
        if defaults.bool(forKey: UserKeys.V2rayDirectCN) {
            let ipJson = JSON(["type": "field", "outboundTag": "direct", "ip": ["geoip:cn"]])
            let domainJson = JSON(["type": "field", "outboundTag": "direct", "domain": ["geosite:cn"]])
            rules.append(ipJson)
            rules.append(domainJson)
        }
        if defaults.bool(forKey: UserKeys.V2rayBlockAD) {
            let adJson = JSON(["type": "field", "outboundTag": "adblock", "domain": ["geosite:category-ads"]])
            rules.insert(adJson, at: 0)
        }
        template["routing"]["rules"] = JSON(rules)
        let data = try template.rawData()
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "v2ray.json"
        try data.write(to: URL(fileURLWithPath: filepath), options: .atomic)
    } catch {
        NSLog("Write haproxy file failed.")
    }
}
