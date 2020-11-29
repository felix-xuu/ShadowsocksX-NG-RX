//
//  BGUtils.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation

let SS_LOCAL_VERSION = "3.3.5"
let PRIVOXY_VERSION = "3.0.28"
let HAPROXY_VERSION = "2.3.1"
let HTTPING_VERSION = "2.5"
let APP_SUPPORT_DIR = "/Library/Application Support/ShadowsocksX-NG-RX/"
let LAUNCH_AGENT_DIR = "/Library/LaunchAgents/"
let LAUNCH_AGENT_CONF_SSLOCAL_NAME = "com.felix.xu.shadowsocksX-NG-RX.local.plist"
let LAUNCH_AGENT_CONF_PRIVOXY_NAME = "com.felix.xu.shadowsocksX-NG-RX.http.plist"
let LAUNCH_AGENT_CONF_HAPROXY_NAME = "com.felix.xu.shadowsocksX-NG-RX.loadbalance.plist"

func getFileSHA1Sum(_ filepath: String) -> String {
    if let data = try? Data(contentsOf: URL(fileURLWithPath: filepath)) {
        return data.sha1()
    }
    return ""
}

//  MARK: httping
func InstallHttping() {
    let fileMgr = FileManager.default
    let homeDir = NSHomeDirectory()
    let appSupportDir = homeDir + APP_SUPPORT_DIR
    if !fileMgr.fileExists(atPath: appSupportDir + "httping-\(HTTPING_VERSION)/httping") || !fileMgr.fileExists(atPath: appSupportDir + "httping") {
        let installerPath = Bundle.main.path(forResource: "install", ofType: "sh")
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: ["httping", HTTPING_VERSION])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Install httping succeeded.")
        } else {
            NSLog("Install httping failed.")
        }
    }
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
    
    var arguments = [sslocalPath, "-c", "ss-local.json", "--reuse-port", "--fast-open"]
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
    if !fileMgr.fileExists(atPath: appSupportDir + "ss-local-\(SS_LOCAL_VERSION)/ss-local") || !fileMgr.fileExists(atPath: appSupportDir + "ss-local") {
        let installerPath = Bundle.main.path(forResource: "install", ofType: "sh")
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: ["ss-local", SS_LOCAL_VERSION])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Install ss-local succeeded.")
        } else {
            NSLog("Install ss-local failed.")
        }
        InstallLib()
    }
    generateSSLocalLauchAgentPlist()
}

func InstallLib() {
    let installerPath = Bundle.main.path(forResource: "install_lib", ofType: "sh")
    let task = Process.launchedProcess(launchPath: installerPath!, arguments: [])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Install lib succeeded.")
    } else {
        NSLog("Install lib failed.")
    }
}

func writeSSLocalConfFile(_ conf:[String:AnyObject]) {
    do {
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "ss-local.json"
        let data: Data = try JSONSerialization.data(withJSONObject: conf, options: .prettyPrinted)
        
        try data.write(to: URL(fileURLWithPath: filepath), options: .atomic)
        NSLog("Write ss-local file succeed.")
    } catch {
        NSLog("Write ss-local file failed.")
    }
}

func removeSSLocalConfFile() {
    let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "ss-local.json"
    try? FileManager.default.removeItem(atPath: filepath)
}

func SyncSSLocal() {
    if ServerProfileManager.activeProfile != nil {
        writeSSLocalConfFile((ServerProfileManager.activeProfile!.toJsonConfig()))
        let on = UserDefaults.standard.bool(forKey: UserKeys.ShadowsocksXOn)
        if on {
            ReloadConfSSLocal()
            SyncPrivoxy()
        }
    } else {
        removeSSLocalConfFile()
        StopSSLocal()
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
    if !fileMgr.fileExists(atPath: appSupportDir + "privoxy-\(PRIVOXY_VERSION)/privoxy") || !fileMgr.fileExists(atPath: appSupportDir + "privoxy") {
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

//  MARK: haproxy
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
        "ProgramArguments": arguments,
        "EnvironmentVariables": ["DYLD_LIBRARY_PATH": NSHomeDirectory() + APP_SUPPORT_DIR]
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
    if !fileMgr.fileExists(atPath: appSupportDir + "haproxy-\(HAPROXY_VERSION)/haproxy") || !fileMgr.fileExists(atPath: appSupportDir + "haproxy") {
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

func writeHaproxyConfFile(type:String) {
    do {
        let defaults = UserDefaults.standard
        let bundle = Bundle.main
        let examplePath = bundle.path(forResource: "haproxy.cfg.example", ofType: nil)
        var example = try String(contentsOfFile: examplePath!, encoding: .utf8)
        example = example.replacingOccurrences(of: "{port}", with: defaults.string(forKey: UserKeys.LoadbalancePort)!)
        var data: Data = Data.init()
        if type == "balance" {
            example = example.replacingOccurrences(of: "{balance strategy}", with: "balance \(defaults.string(forKey: UserKeys.LoadbalanceStrategy)!)")
            example = example.replacingOccurrences(of: "{use_backend strategy}", with: "")
            var profiles: [ServerProfile]
            if UserDefaults.standard.bool(forKey: UserKeys.LoadbalanceEnableAllNodes) {
                profiles = LoadBalance.getLoadBalanceGroup()!.serverProfiles
            } else {
                profiles = LoadBalance.getLoadBalanceProfiles()
            }
            var servers: String = ""
            for item in profiles {
                servers.append(contentsOf: "server \(item.serverHost)-\(UUID().hashValue) \(item.serverHost):\(item.serverPort) check\n    ")
            }
            example = example.replacingOccurrences(of: "{backend_default}", with: servers)
            data = example.data(using: .utf8) ?? Data.init()
        } else if type == "rule" {
            example = example.replacingOccurrences(of: "{balance strategy}", with: "")
            let defaultProfile = ServerProfileManager.activeProfile
            let defaultProxy =  "server \(defaultProfile!.serverHost)-\(UUID().hashValue) \(defaultProfile!.serverHost):\(defaultProfile!.serverPort)"
            example = example.replacingOccurrences(of: "{backend_default}", with: defaultProxy)
            
            var acls = ""
            var backends = ""
            if let ruleConfigs = RuleManager.getRuleConfigs() {
                for item in ruleConfigs {
                    if !item.enable {
                        continue
                    }
                    if let p = item.profile {
                        let backendName = "\(item.name ?? "ruleName")-\(UUID().hashValue)"
                        var acl = "use_backend \(backendName) if { dst "
                        var needAdd = false
                        let rules = item.rules.split(separator: "\n")
                        for rule in rules {
                            if rule.starts(with: "#") {
                                continue
                            }
                            acl.append(String(rule))
                            acl.append(" ")
                            needAdd = true
                        }
                        acl.append("}\n    ")
                        if needAdd {
                            acls.append(acl)
                            backends.append("backend \(backendName)\n    server \(p.serverHost) \(p.serverHost):\(p.serverPort)\n")
                        }
                    }
                }
            }
            example = example.replacingOccurrences(of: "{use_backend strategy}", with: acls)
            data = example.data(using: .utf8) ?? Data.init()
            data.append(contentsOf: backends.utf8)
        }
        let filepath = NSHomeDirectory() + APP_SUPPORT_DIR + "haproxy.cfg"
        try data.write(to: URL(fileURLWithPath: filepath), options: .atomic)
    } catch {
        NSLog("Write haproxy file failed.")
    }
}
