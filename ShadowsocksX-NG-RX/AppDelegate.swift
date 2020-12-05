//
//  AppDelegate.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix on 2019/8/13.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    
    // MARK: Controllers
    var qrcodeWinCtrl: SWBQRCodeWindowController!
    var preferencesWinCtrl: PreferencesWindowController!
    var advPreferencesWinCtrl: AdvPreferencesWindowController!
    var dnsPreferencesWinCtrl: DNSPreferencesController!
    var subscribePreferenceWinCtrl: SubscribePreferenceWindowController!
    var loadBalancePreferenceController: LoadBalancePreferenceController!
    var ruleConfigPreferenceController: RuleConfigPreferenceController!
    
    var statusItem: NSStatusItem!
    var keys: [String : String] = [:]
    let networkMonitor: NetWorkMonitor = NetWorkMonitor()
    var modeKey = [String : String]()
    
    @IBOutlet var statusMenu: NSMenu!
    @IBOutlet var toggleRunningMenuItem: NSMenuItem!
    @IBOutlet var serversMenu: NSMenu!
    @IBOutlet var serversMenuItem: NSMenuItem!
    @IBOutlet var manualUpdateSubscribeMenuItem: NSMenuItem!
    @IBOutlet var ShowNetworkSpeedItem: NSMenuItem!
    @IBOutlet var launchAtLoginMenuItem: NSMenuItem!
    @IBOutlet var languageMenuItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSUserNotificationCenter.default.delegate = self
        
        // Prepare defaults
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            UserKeys.ShadowsocksXOn: true,
            UserKeys.ShadowsocksXRunningMode: UserKeys.Mode_Manual,
            UserKeys.Socks5_ListenAddress: "127.0.0.1",
            UserKeys.Socks5_ListenPort: NSNumber(value: 1086 as UInt16),
            UserKeys.ListenAddress: "127.0.0.1",
            UserKeys.Socks5_Timeout: NSNumber(value: 60 as UInt8),
            UserKeys.Socks5_EnableUDPRelay: false,
            UserKeys.Socks5_EnableVerboseMode: false,
            UserKeys.HTTP_ListenAddress: "127.0.0.1",
            UserKeys.HTTP_ListenPort: NSNumber(value: 1087 as UInt16),
            UserKeys.LoadbalancePort: NSNumber(value: 1089 as UInt16),
            UserKeys.HTTPOn: true,
            UserKeys.FollowGlobal: true,
            UserKeys.ServerGroups: [],
            UserKeys.ShowSpeed: false,
            UserKeys.LaunchAtLogin: false,
            UserKeys.Language: "en",
            UserKeys.LoadbalanceEnableAllNodes: true,
            UserKeys.OrderRemark: false,
            UserKeys.OrderAddress: true,
            UserKeys.DNSEnable: false,
            UserKeys.RuleDefaultFlow: "direct",
            ])

        cleanLogs()
        initManager()
        initInstall()
        initLanguageSelector()
        initModeSelector()
        initNotificationObserver()
        initKeys()
        
        setupProxy()
        initSleepListener()
        DNSServersChange()
        initExceptionHandler()

        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.setUpMenuBar()
                self.updateModeMenuItemState()
                self.updateLanguageMenuItemState()
                self.updateCommonMenuItemState()
                self.updateServersMenu()
                self.updateServerMenuItemState()
                self.updateLocalizedMenu()
                NSLog("ShadowsocksX running")
            }
        }
    }
    
    func cleanLogs() {
        let bundle = Bundle.main
        let installerPath = bundle.path(forResource: "clean_logs", ofType: "sh")
        let task = Process.launchedProcess(launchPath: installerPath!, arguments: [])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            NSLog("Clean logs succeeded.")
        } else {
            NSLog("Clean logs failed.")
        }
    }
    
    func initKeys() {
        for item in statusMenu.items {
            if !item.isSeparatorItem {
                item.setAccessibilityValueDescription(item.title)
                keys[item.title] = item.title
                if item.hasSubmenu && item.accessibilityIdentifier() != "language" {
                    for subItem in item.submenu!.items {
                        if !subItem.isSeparatorItem {
                            subItem.setAccessibilityValueDescription(subItem.title)
                            keys[subItem.title] = subItem.title
                            if item.accessibilityIdentifier() == "mode" {
                                modeKey[subItem.accessibilityIdentifier()] = subItem.title
                            }
                        }
                    }
                }
            }
        }
    }
    
    func initInstall() {
        InstallLib()
        InstallSSLocal()
        InstallPrivoxy()
        InstallHaproxy()
        InstallHttping()
        setPassby()
    }
    
    func initLanguageSelector() {
        for item in languageMenuItem.submenu!.items {
            item.action = #selector(AppDelegate.updateLanguage)
        }
    }
    
    func initManager() {
        let _ = ServerProfileManager.instance
        let _ = ServerGroupManager.instance
    }
    
    @objc func updateLanguage(_ sender: NSMenuItem) {
        UserDefaults.standard.setValue(sender.accessibilityIdentifier(), forKey: UserKeys.Language)
        NSLog("Changed language to: %@(%@)", sender.title, sender.accessibilityIdentifier())
        updateLanguageMenuItemState()
        // update localized menu
        updateLocalizedMenu()
        updateServerMenuItemState()
    }
    
    func updateLanguageMenuItemState() {
        let currentLanguage = UserDefaults.standard.string(forKey: UserKeys.Language)
        for item in languageMenuItem.submenu!.items {
            item.state = NSControl.StateValue(rawValue: currentLanguage == item.accessibilityIdentifier() ? 1 : 0)
        }
    }
    
    func updateLocalizedMenu() {
        let defaults = UserDefaults.standard
        for item in statusMenu.items {
            if item.accessibilityIdentifier() == "switch" {
                let key = keys[item.accessibilityValueDescription()!]
                if defaults.bool(forKey: UserKeys.ShadowsocksXOn){
                    item.title = key!.replacingOccurrences(of: "On", with: "Off").localized
                } else {
                    item.title = key!.localized
                }
            } else if !item.isSeparatorItem && item.accessibilityIdentifier() != "active" {
                item.title = keys[item.accessibilityValueDescription()!]!.localized
                if item.hasSubmenu && item.accessibilityIdentifier() != "language" {
                    for subItem in item.submenu!.items {
                        if !subItem.isSeparatorItem && subItem.accessibilityIdentifier() != "server" {
                            subItem.title = keys[subItem.accessibilityValueDescription()!]!.localized
                        }
                    }
                }
            }
        }
    }
    
    func initSleepListener() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),name: NSWorkspace.didWakeNotification, object: nil)
    }
    
    @objc private func sleepListener(_ aNotification: Notification) {
        if aNotification.name == NSWorkspace.willSleepNotification {
            print("Going to sleep")
            if UserDefaults.standard.bool(forKey: UserKeys.ShowSpeed) {
                networkMonitor.stop()
            }
        } else if aNotification.name == NSWorkspace.didWakeNotification {
            print("Woke up")
            if UserDefaults.standard.bool(forKey: UserKeys.ShowSpeed) {
                networkMonitor.start()
            }
        }
    }
    
    func initNotificationObserver() {
        let notifyCenter = NotificationCenter.default
        
        notifyCenter.addObserver(forName: NSNotification.Name(rawValue: DNS_CONF_CHANGED), object: nil, queue: nil
            , using: {
                (note) in
                DNSServersChange()
            }
        )
        notifyCenter.addObserver(forName: NSNotification.Name(rawValue: NOTIFY_ADV_CONF_CHANGED), object: nil, queue: nil
            , using: {
                (note) in
                setupProxy()
            }
        )
        notifyCenter.addObserver(forName: NSNotification.Name(rawValue: NOTIFY_FOUND_SS_URL), object: nil, queue: nil) {
            (note: Notification) in
            if let userInfo = (note as NSNotification).userInfo {
                let urls: [URL] = userInfo["urls"] as! [URL]
                if urls.count == 0 {
                    if userInfo["source"] as! String == "qrcode" {
                        notificationDeliver(title: "No QR code found", subTitle: "", text: "")
                    } else if userInfo["source"] as! String == "pasteboard" {
                        notificationDeliver(title: "No URL found", subTitle: "", text: "")
                    }
                    return
                }
                
                var isChanged = false
                
                let group = ServerGroup()
                group.groupName = "Default Group".localized
                
                for url in urls {
                    let profielDict = ParseAppURLSchemes(url: url)//ParseSSURL(url)
                    if let profielDict = profielDict {
                        let profile = ServerProfile.fromDictionary(profielDict as [String : AnyObject])
                        profile.groupId = group.groupId
                        if profile.group.isEmpty {
                            profile.group = group.groupName
                        }
                        group.serverProfiles.append(profile)
                        isChanged = true
                        let title = "Add ShadowsocksX Server Profile"
                        let text = "Host: \(profile.serverHost) Port: \(profile.serverPort)"
                        if userInfo["source"] as! String == "qrcode" {
                            notificationDeliver(title: title, subTitle: "By scan QR Code", text: text)
                        } else if userInfo["source"] as! String == "pasteboard" {
                            notificationDeliver(title: title, subTitle: "By Handle SS URL", text: text)
                        }
                    } else {
                        notificationDeliver(title: "Failed to Add Server Profile", subTitle: "Address can not be recognized", text: "")
                    }
                }
                if isChanged {
                    ServerGroupManager.serverGroups.append(group)
                    ServerGroupManager.save()
                    self.updateServersMenu()
                    self.updateServerMenuItemState()
                }
            }
        }
    }
    
    func initModeSelector() {
        for item in statusMenu.items {
            if item.accessibilityIdentifier() == "mode" {
                for sub in item.submenu!.items {
                    sub.action = #selector(AppDelegate.changeMode)
                }
            }
        }
    }
    
    @objc func changeMode(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        let mode = sender.accessibilityIdentifier()
        if mode == defaults.string(forKey: UserKeys.ShadowsocksXRunningMode) {
            return
        }
        defaults.setValue(mode, forKey: UserKeys.ShadowsocksXRunningMode)
        NSLog("Changed mode to: %@(%@)", sender.title, mode)
        updateModeMenuItemState()
        for item in statusMenu.items {
            if item.accessibilityIdentifier() == "mode" {
                item.title = keys[item.accessibilityValueDescription()!]!.localized
            }
        }
        // change Menu bar
        let image = NSImage(named: "menu_icon_" + mode)
        image!.isTemplate = true
        statusItem!.button!.image = image
        if !defaults.bool(forKey: UserKeys.ShadowsocksXOn) {
            return
        }
        setupProxy()
        updateServerMenuItemState()
    }
    
    func updateModeMenuItemState() {
        let currentMode = UserDefaults.standard.string(forKey: UserKeys.ShadowsocksXRunningMode)
        for item in statusMenu.items {
            if item.accessibilityIdentifier() == "mode" {
                for sub in item.submenu!.items {
                    if currentMode == sub.accessibilityIdentifier() {
                        sub.state = NSControl.StateValue(rawValue: 1)
                        keys[item.accessibilityValueDescription()!] = sub.accessibilityValueDescription()!
                        item.state = NSControl.StateValue(rawValue: 1)
                    } else {
                        sub.state = NSControl.StateValue(rawValue: 0)
                    }
                }
            }
        }
    }
    
    @IBAction func toggleRunning(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        var image = NSImage()
        for item in statusMenu.items {
            if item.accessibilityIdentifier() == "switch" {
                let key = keys[item.accessibilityValueDescription()!]
                if defaults.bool(forKey: UserKeys.ShadowsocksXOn){
                    NSLog("Shut down ShadowsocksX")
                    item.title = key!.localized
                    image = NSImage(named: "menu_icon_disabled")!
                } else {
                    NSLog("Start up ShadowsocksX")
                    item.title = key!.replacingOccurrences(of: "On", with: "Off").localized
                    image = NSImage(named: "menu_icon_" + defaults.string(forKey: UserKeys.ShadowsocksXRunningMode)!)!
                }
                break
            }
        }
        image.isTemplate = true
        statusItem.button!.image = image
        defaults.set(!defaults.bool(forKey: UserKeys.ShadowsocksXOn), forKey: UserKeys.ShadowsocksXOn)
        setupProxy()
    }
    
    @IBAction func editSubscribe(_ sender: NSMenuItem) {
        subscribePreferenceWinCtrl = SubscribePreferenceWindowController(windowNibName: "SubscribePreferenceWindowController")
        subscribePreferenceWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        subscribePreferenceWinCtrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func toggleLaunghAtLogin(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: UserKeys.LaunchAtLogin), forKey: UserKeys.LaunchAtLogin)
        let appId = "com.felix.xu.LaunchHelper"
        SMLoginItemSetEnabled(appId as CFString, defaults.bool(forKey: UserKeys.LaunchAtLogin))
        updateCommonMenuItemState()
    }
    
    @IBAction func showQRCodeForCurrentServer(_ sender: NSMenuItem) {
        qrcodeWinCtrl = SWBQRCodeWindowController(windowNibName: "SWBQRCodeWindowController")
        var errMsg: String!
        if let profile = ServerProfileManager.activeProfile {
            if profile.isValid() {
                qrcodeWinCtrl.qrCode = profile.URL()
                qrcodeWinCtrl.title = profile.title()
                qrcodeWinCtrl.window?.title = "QR Code".localized
                qrcodeWinCtrl.qrCopyButton.title = "Copy to Clipboard".localized
                qrcodeWinCtrl.showWindow(self)
                NSApp.activate(ignoringOtherApps: true)
                qrcodeWinCtrl.window?.makeKeyAndOrderFront(nil)
                return
            } else {
                errMsg = "Current server profile is invalid"
            }
        } else {
            errMsg = "No activated server"
        }
        notificationDeliver(title: errMsg, subTitle: "", text: "")
    }
    
    @IBAction func scanQRCodeFromScreen(_ sender: NSMenuItem) {
        ScanQRCodeOnScreen()
    }
    
    @IBAction func updateSubscribe(_ sender: NSMenuItem) {
        SubscribeManager.updateAllServerFromSubscribe()
    }
    
    @IBAction func editServerPreferences(_ sender: NSMenuItem) {
        preferencesWinCtrl = PreferencesWindowController(windowNibName: "PreferencesWindowController")
        preferencesWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        preferencesWinCtrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func editAdvPreferences(_ sender: NSMenuItem) {
        advPreferencesWinCtrl = AdvPreferencesWindowController(windowNibName: "AdvPreferencesWindowController")
        advPreferencesWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        advPreferencesWinCtrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func editDNSPreferences(_ sender: NSObject) {
        dnsPreferencesWinCtrl = DNSPreferencesController(windowNibName: "DNSPreferencesController")
        dnsPreferencesWinCtrl.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        dnsPreferencesWinCtrl.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func ruleConfigPreferences(_ sender: NSObject) {
        ruleConfigPreferenceController = RuleConfigPreferenceController(windowNibName: "RuleConfigPreferenceController")
        ruleConfigPreferenceController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        ruleConfigPreferenceController.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func doPingTest(_ sender: AnyObject) {
        PingServers.instance.ping()
    }
    
    @IBAction func loadbalancePreference(_ sender: AnyObject) {
        loadBalancePreferenceController = LoadBalancePreferenceController(windowNibName: "LoadBalancePreferenceController")
        loadBalancePreferenceController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        loadBalancePreferenceController.window?.makeKeyAndOrderFront(self)
    }
    
    @IBAction func showSpeedTap(_ sender: NSMenuItem) {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: UserKeys.ShowSpeed), forKey: UserKeys.ShowSpeed)
        updateCommonMenuItemState()
        setUpMenuBar()
    }
    
    @IBAction func showLogs(_ sender: NSMenuItem) {
        let fileMgr = FileManager.default
        let path = NSHomeDirectory() + "/Library/Logs/ssr-local.log"
        if !fileMgr.fileExists(atPath: path) {
            let alert = NSAlert.init()
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: "OK".localized)
            alert.messageText = "Warning".localized
            alert.informativeText = "Log not exist".localized
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
            return
        }
        NSWorkspace.shared.openFile(path, withApplication: "Console")
    }
    
    @IBAction func showAbout(_ sender: NSMenuItem) {
        NSApp.orderFrontStandardAboutPanel(sender);
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func importProfileURLFromPasteboard(_ sender: NSMenuItem) {
        let pb = NSPasteboard.general
        if #available(OSX 10.13, *) {
            if let text = pb.string(forType: NSPasteboard.PasteboardType.URL) {
                if let url = URL(string: text) {
                    NotificationCenter.default.post(
                        name: Notification.Name(rawValue: NOTIFY_FOUND_SS_URL), object: nil
                        , userInfo: [
                            "urls": [url],
                            "source": "pasteboard",
                        ])
                    return
                }
            }
        }
        if let text = pb.string(forType: NSPasteboard.PasteboardType.string) {
            var urls = text.components(separatedBy: .newlines)
                .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .map { URL(string: $0) }
                .filter { $0 != nil }
                .map { $0! }
            urls = urls.filter { $0.absoluteString.hasPrefix(UserKeys.SSPrefix) || $0.absoluteString.hasPrefix(UserKeys.SSRPrefix) }
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: NOTIFY_FOUND_SS_URL), object: nil
                , userInfo: [
                    "urls": urls,
                    "source": "pasteboard",
                ])
        }
    }
    
    @objc func selectServer(_ sender: NSMenuItem) {
        let mode = UserDefaults.standard.string(forKey: UserKeys.ShadowsocksXRunningMode)
        if mode == UserKeys.Mode_Loadbalance {
            return
        }
        let index = sender.tag
        let gIndex = sender.parent!.tag
        let newProfile = ServerGroupManager.serverGroups[gIndex].serverProfiles[index]
        ServerProfileManager.setActiveProfile(newProfile)
        if mode == UserKeys.Mode_Rule {
            RuleManager.enableRuleFlow()
        } else if mode == UserKeys.Mode_Manual || mode == UserKeys.Mode_Global {
            writeSSLocalConfFile(newProfile.toJsonConfig())
            ReloadConfSSLocal()
        }
        updateServersMenu()
        updateServerMenuItemState()
    }
    
    func updateServersMenu() {
        for item in serversMenuItem.submenu!.items {
            if item.accessibilityIdentifier() == "server" {
                serversMenu.removeItem(item)
            }
        }
        for (gIndex, g) in ServerGroupManager.serverGroups.enumerated() {
            if gIndex == 0 {
                serversMenuItem.submenu?.insertItem(NSMenuItem.separator(), at: 0)
            }
            let groupMenu = NSMenu()
            let groupItem = NSMenuItem()
            groupItem.title = g.groupName
            groupItem.tag = gIndex
            groupItem.setAccessibilityIdentifier("server")
            groupItem.setAccessibilityValueDescription(g.groupId)
            serversMenuItem.submenu?.insertItem(groupItem, at: 0)
            serversMenuItem.submenu?.setSubmenu(groupMenu, for: groupItem)
            
            let profiles = g.serverProfiles
            var item: NSMenuItem
            for (index, profile) in profiles.enumerated() {
                item = NSMenuItem()
                item.tag = index
                item.action = #selector(AppDelegate.selectServer)
                item.title = profile.title()
                item.setAccessibilityIdentifier("server")
                item.setAccessibilityValueDescription(profile.getValidId())
                groupItem.submenu?.addItem(item)
            }
        }
    }
    
    func updateServerMenuItemState() {
        for item in statusMenu.items {
            if item.accessibilityIdentifier() == "active" {
                statusMenu.removeItem(item)
            }
        }
        let mode = UserDefaults.standard.string(forKey: UserKeys.ShadowsocksXRunningMode)
        if mode == UserKeys.Mode_Loadbalance {
            for item in serversMenuItem.submenu!.items {
                if item.accessibilityIdentifier() == "server" {
                    if item.accessibilityValueDescription() == LoadBalance.getLoadBalanceGroup()?.groupId {
                        item.state = NSControl.StateValue(1)
                        for subItem in item.submenu!.items {
                            if UserDefaults.standard.bool(forKey: UserKeys.LoadbalanceEnableAllNodes) {
                                subItem.state = NSControl.StateValue(1)
                            } else {
                                subItem.state = NSControl.StateValue(LoadBalance.getLoadBalanceProfiles().contains(where: {$0.getValidId() == subItem.accessibilityValueDescription()}) ? 1 : 0)
                            }
                        }
                    } else {
                        item.state = NSControl.StateValue(0)
                        for subItem in item.submenu!.items {
                            subItem.state = NSControl.StateValue(0)
                        }
                    }
                }
            }
            let separator = NSMenuItem.separator()
            separator.setAccessibilityIdentifier("active")
            statusMenu!.insertItem(separator, at: 1)
            statusMenu!.insertItem(withTitle: "Active Group: ".localized + LoadBalance.getLoadBalanceGroup()!.groupName, action: nil, keyEquivalent: "", at: 2).setAccessibilityIdentifier("active")
            
            let nodesSelected = String(UserDefaults.standard.bool(forKey: UserKeys.LoadbalanceEnableAllNodes) ? LoadBalance.getLoadBalanceGroup()!.serverProfiles.count : LoadBalance.getLoadBalanceProfiles().count)
            statusMenu!.insertItem(withTitle: "Load Balance - ".localized + LoadBalance.strategies.first(where: {$0.0 == UserDefaults.standard.string(forKey: UserKeys.LoadbalanceStrategy)})!.1.localized + " (\(nodesSelected)" + " Nodes Selected".localized + ")", action: nil, keyEquivalent: "", at: 3).setAccessibilityIdentifier("active")
        } else if let profile = ServerProfileManager.activeProfile {
            if mode == UserKeys.Mode_Rule {
                let ruleConfigValidIds = RuleManager.getRuleConfigs().filter({$0.enable && $0.profile != nil && $0.profile.groupId == profile.groupId}).map({$0.profile.getValidId()})
                for item in serversMenuItem.submenu!.items {
                    if item.accessibilityIdentifier() == "server" {
                        if item.accessibilityValueDescription() == profile.groupId {
                            item.state = NSControl.StateValue(1)
                            for subItem in item.submenu!.items {
                                let needEnable = profile.getValidId() == subItem.accessibilityValueDescription() || ruleConfigValidIds.contains(subItem.accessibilityValueDescription()!)
                                subItem.state = NSControl.StateValue(needEnable ? 1 : 0)
                            }
                        } else {
                            item.state = NSControl.StateValue(0)
                            for subItem in item.submenu!.items {
                                subItem.state = NSControl.StateValue(0)
                            }
                        }
                    }
                }
                let separator = NSMenuItem.separator()
                separator.setAccessibilityIdentifier("active")
                statusMenu!.insertItem(separator, at: 1)
                let activeGroupTitle = "Active Group: ".localized + ServerGroupManager.getServerGroupByGroupId(profile.groupId)!.groupName + " ({nums} rules effective)".localized.replacingOccurrences(of: "{nums}", with: String(ruleConfigValidIds.count))
                statusMenu!.insertItem(withTitle: activeGroupTitle, action: nil, keyEquivalent: "", at: 2).setAccessibilityIdentifier("active")
                statusMenu!.insertItem(withTitle: "Default Node: ".localized + (ServerGroupManager.getServerGroupByGroupId(profile.groupId)?.serverProfiles.first(where: {$0.getValidId() == profile.getValidId()})!.titleForActive())!, action: nil, keyEquivalent: "", at: 3).setAccessibilityIdentifier("active")
                DispatchQueue.global().async {
                    let location = PingServers.instance.getLocation()
                    let latency = PingServers.instance.pingCurrent()
                    self.statusMenu!.insertItem(withTitle: "\("Actually Location: ".localized)\(location)   \("Latency: ".localized)\(latency ?? "-")ms", action: #selector(AppDelegate.refreshLocationAndLatency), keyEquivalent: "", at: 4).setAccessibilityIdentifier("active")
                }
            } else {
                for item in serversMenuItem.submenu!.items {
                    if item.accessibilityIdentifier() == "server" {
                        if item.accessibilityValueDescription() == profile.groupId {
                            item.state = NSControl.StateValue(1)
                            for subItem in item.submenu!.items {
                                subItem.state = NSControl.StateValue(profile.getValidId() == subItem.accessibilityValueDescription() ? 1 : 0)
                            }
                        } else {
                            item.state = NSControl.StateValue(0)
                            for subItem in item.submenu!.items {
                                subItem.state = NSControl.StateValue(0)
                            }
                        }
                    }
                }
                let separator = NSMenuItem.separator()
                separator.setAccessibilityIdentifier("active")
                statusMenu!.insertItem(separator, at: 1)
                statusMenu!.insertItem(withTitle: "Active Group: ".localized + ServerGroupManager.getServerGroupByGroupId(profile.groupId)!.groupName, action: nil, keyEquivalent: "", at: 2).setAccessibilityIdentifier("active")
                statusMenu!.insertItem(withTitle: "Active Node: ".localized + (ServerGroupManager.getServerGroupByGroupId(profile.groupId)?.serverProfiles.first(where: {$0.getValidId() == profile.getValidId()})!.titleForActive())!, action: nil, keyEquivalent: "", at: 3).setAccessibilityIdentifier("active")
                DispatchQueue.global().async {
                    let location = PingServers.instance.getLocation()
                    let latency = PingServers.instance.pingCurrent()
                    self.statusMenu!.insertItem(withTitle: "\("Actually Location: ".localized)\(location)   \("Latency: ".localized)\(latency ?? "-")ms", action: #selector(AppDelegate.refreshLocationAndLatency), keyEquivalent: "", at: 4).setAccessibilityIdentifier("active")
                }
            }
        }
    }
    
    @objc func refreshLocationAndLatency(){
        DispatchQueue.global().async {
            let location = PingServers.instance.getLocation()
            let latency = PingServers.instance.pingCurrent()
            self.statusMenu!.item(at: 4)?.title = "\("Actually Location: ".localized)\(location)   \("Latency: ".localized)\(latency ?? "-")ms"
        }
    }
    
    func setUpMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let defaults = UserDefaults.standard
        let image = defaults.bool(forKey: UserKeys.ShadowsocksXOn) ? NSImage(named: "menu_icon_" + defaults.string(forKey: UserKeys.ShadowsocksXRunningMode)!)! : NSImage(named: "menu_icon_disabled")!
        statusItem.menu = statusMenu
        image.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.imagePosition = NSControl.ImagePosition.imageRight
        if defaults.bool(forKey: UserKeys.ShowSpeed) {
            networkMonitor.start()
        } else {
            networkMonitor.stop()
        }
    }
    
    func updateNetSpeed(inbound: String, outbound: String) {
        if !UserDefaults.standard.bool(forKey: UserKeys.ShowSpeed) {
            return
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        let fontAttributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize:CGFloat(9)), NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.baselineOffset: NSNumber(-5)]
        statusItem.button?.attributedTitle = NSAttributedString(string: "\(outbound) ↑\n\(inbound) ↓", attributes: fontAttributes)
    }
    
    func updateCommonMenuItemState() {
        let defaults = UserDefaults.standard
        ShowNetworkSpeedItem.state = NSControl.StateValue(rawValue: defaults.bool(forKey: UserKeys.ShowSpeed) ? 1 : 0)
        launchAtLoginMenuItem.state = NSControl.StateValue(rawValue: defaults.bool(forKey: UserKeys.LaunchAtLogin) ? 1 : 0)
    }
    
    // MARK: NSUserNotificationCenterDelegate
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        StopSSLocal()
        StopPrivoxy()
        disableProxy()
        StopHaproxy()
        networkMonitor.stop()
        NSLog("ShadowsocksX stopped")
    }
    
    func initExceptionHandler() {
        NSSetUncaughtExceptionHandler(uncaughtExceptionHandler)
        signal(SIGABRT, signalExceptionHandler)
        signal(SIGILL, signalExceptionHandler)
        signal(SIGKILL, signalExceptionHandler)
        signal(SIGSEGV, signalExceptionHandler)
        signal(SIGFPE, signalExceptionHandler)
        signal(SIGBUS, signalExceptionHandler)
        signal(SIGPIPE, signalExceptionHandler)
        signal(SIGTRAP, signalExceptionHandler)
    }
}

