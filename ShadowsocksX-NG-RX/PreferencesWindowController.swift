//
//  PreferencesWindowController.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var profilesTableView: NSTableView!
    @IBOutlet weak var groupsTableView: NSTableView!
    
    @IBOutlet weak var profileBox: NSBox!
    
    @IBOutlet weak var hostTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    @IBOutlet weak var methodTextField: NSComboBox!
    @IBOutlet weak var ProtocolTextField: NSComboBox!
    @IBOutlet weak var ProtocolParamTextField: NSTextField!
    @IBOutlet weak var ObfsTextField: NSComboBox!
    @IBOutlet weak var ObfsParamTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSTextField!
    @IBOutlet weak var pwdTextField: NSTextField!
    @IBOutlet weak var remarkTextField: NSTextField!
    @IBOutlet weak var groupTextField: NSTextField!
    @IBOutlet weak var urlTextField: NSTextField!
    
    @IBOutlet weak var duplicateGroupButton: NSButton!
    @IBOutlet weak var removeGroupButton: NSButton!
    @IBOutlet weak var duplicateProfileButton: NSButton!
    @IBOutlet weak var removeProfileButton: NSButton!
    @IBOutlet weak var copyURLBtn: NSButton!
    @IBOutlet weak var eyeButton: NSButton!
    
    @IBOutlet weak var orderAddress: NSButton!
    @IBOutlet weak var orderRemark: NSButton!
    
    var defaults: UserDefaults!
    
    var editingProfile: ServerProfile!
    
    var keys: [String : String] = [:]
    var showPassword: Bool = false
    var removedActiveProfile: Bool = false
    var loadBalanceGroup: ServerGroup?
    var loadBalanceProfiles: [ServerProfile]!
    var loadBalanceProfilesChanged: Bool = false
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        defaults = UserDefaults.standard
        methodTextField.addItems(withObjectValues: [
            "none",
            "rc4-md5",
            "aes-128-gcm",
            "aes-192-gcm",
            "aes-256-gcm",
            "aes-128-cfb",
            "aes-192-cfb",
            "aes-256-cfb",
            "aes-128-ctr",
            "aes-192-ctr",
            "aes-256-ctr",
            "bf-cfb",
            "camellia-128-cfb",
            "camellia-192-cfb",
            "camellia-256-cfb",
            "salsa20",
            "chacha20",
            "chacha20-ietf",
            "chacha20-ietf-poly1305",
            "xchacha20-ietf-poly1305",
            ])
        ProtocolTextField.addItems(withObjectValues: [
            "origin",
            "auth_sha1_v4",
            "auth_sha1_v4_compatible",
            "auth_aes128_sha1",
            "auth_aes128_md5",
            "auth_chain_a",
            "auth_chain_b",
            "auth_chain_c",
            "auth_chain_d",
            ])
        ObfsTextField.addItems(withObjectValues: [
            "plain",
            "http_simple",
            "http_simple_compatible",
            "http_post",
            "http_post_compatible",
            "tls1.2_ticket_auth",
            "tls1.2_ticket_auth_compatible",
            ])
        if defaults.bool(forKey: UserKeys.OrderAddress) {
            orderAddress.state = .on
            orderRemark.state = .off
        } else {
            orderAddress.state = .off
            orderRemark.state = .on
        }
        loadBalanceGroup = LoadBalance.getLoadBalanceGroup()
        loadBalanceProfiles = LoadBalance.getLoadBalanceProfiles()
        groupsTableView.reloadData()
        profilesTableView.reloadData()
        updateProfileBoxVisible()
        bindProfile(0, 0)
        displayPassword(eyeButton)
        initKeys()
        keyLocalize()
    }
    
    func initKeys() {
        self.window!.setAccessibilityValueDescription(self.window!.title)
        keys[self.window!.title] = self.window!.title
        for item in profileBox.superview!.subviews {
            if item.tag == 1 && item is NSButton {
                let button = item as! NSButton
                button.setAccessibilityValueDescription(button.title)
                keys[button.title] = button.title
            } else if item.tag == 1 && item is NSTextField {
                let textField = item as! NSTextField
                textField.setAccessibilityValueDescription(textField.stringValue)
                keys[textField.stringValue] = textField.stringValue
            }
        }
        for item in hostTextField.superview!.subviews {
            if item.tag == 1 {
                if item is NSTextField {
                    let textField = item as! NSTextField
                    textField.setAccessibilityValueDescription(textField.stringValue)
                    keys[textField.stringValue] = textField.stringValue
                } else if item is NSButton {
                    let button = item as! NSButton
                    button.setAccessibilityValueDescription(button.title)
                    keys[button.title] = button.title
                }
            }
        }
    }
    
    func keyLocalize() {
        self.window!.title = keys[self.window!.accessibilityValueDescription()!]!.localized
        for item in profileBox.superview!.subviews {
            if item.tag == 1 && item is NSButton {
                let button = item as! NSButton
                button.title = keys[button.accessibilityValueDescription()!]!.localized
            } else if item.tag == 1 && item is NSTextField {
                let textFiled = item as! NSTextField
                textFiled.stringValue = keys[textFiled.accessibilityValueDescription()!]!.localized
            }
        }
        for item in hostTextField.superview!.subviews {
            if item.tag == 1 {
                if item is NSTextField {
                    let textField = item as! NSTextField
                    textField.stringValue = keys[textField.accessibilityValueDescription()!]!.localized
                } else if item is NSButton {
                    let button = item as! NSButton
                    button.title = keys[button.accessibilityValueDescription()!]!.localized
                }
            }
        }
    }
    
    override func awakeFromNib() {
        groupsTableView.allowsMultipleSelection = true
        profilesTableView.allowsMultipleSelection = true
    }
    
    @IBAction func addProfile(_ sender: NSButton) {
        if ServerGroupManager.serverGroups.isEmpty {
            addGroup(NSButton())
        }
        
        let profile = ServerProfile()
        profile.remark = "New Server".localized
        profile.groupId = ServerGroupManager.serverGroups[groupsTableView.selectedRow].groupId
        profile.group = ServerGroupManager.serverGroups[groupsTableView.selectedRow].groupName
        ServerGroupManager.serverGroups[groupsTableView.selectedRow].serverProfiles.insert(profile, at: 0)

        profilesTableView.beginUpdates()
        profilesTableView.insertRows(at: IndexSet(integer: 0), withAnimation: .effectFade)
        profilesTableView.scrollRowToVisible(0)
        profilesTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        profilesTableView.endUpdates()
        updateProfileBoxVisible()
    }
    
    @IBAction func removeProfile(_ sender: NSButton) {
        let index = Int(profilesTableView.selectedRowIndexes.first!)
        var deleteCount = 0
        profilesTableView.beginUpdates()
        for toDeleteIndex in profilesTableView.selectedRowIndexes {
            if let activeProfile = ServerProfileManager.activeProfile {
                if activeProfile.uuid == ServerGroupManager.serverGroups[groupsTableView.selectedRow].serverProfiles[toDeleteIndex - deleteCount].uuid {
                    removedActiveProfile = true
                }
            }
            ServerGroupManager.serverGroups[groupsTableView.selectedRow].serverProfiles.remove(at: toDeleteIndex - deleteCount)
            profilesTableView.removeRows(at: IndexSet(integer: toDeleteIndex - deleteCount), withAnimation: .effectFade)
            if ServerGroupManager.serverGroups[groupsTableView.selectedRow].isSubscription && loadBalanceProfiles.contains(where: {$0.hashVal == ServerGroupManager.serverGroups[groupsTableView.selectedRow].serverProfiles[toDeleteIndex - deleteCount].hashVal}) {
                loadBalanceProfiles.removeAll(where: {$0.hashVal == ServerGroupManager.serverGroups[groupsTableView.selectedRow].serverProfiles[toDeleteIndex - deleteCount].hashVal})
                loadBalanceProfilesChanged = true
            }
            deleteCount += 1
        }
        profilesTableView.scrollRowToVisible(index == 0 ? 0 : index - 1)
        profilesTableView.selectRowIndexes(IndexSet(integer: index == 0 ? 0 : index - 1), byExtendingSelection: false)
        profilesTableView.endUpdates()
        updateProfileBoxVisible()
    }
    
    @IBAction func duplicateProfile(_ sender: NSButton) {
        if profilesTableView.selectedRowIndexes.count != 1 {
            return
        }
        let index = profilesTableView.selectedRow
        var group = ServerGroupManager.serverGroups[groupsTableView.selectedRow]
        let newProfile = ServerProfile.fromDictionary(ServerProfile.toDictionary(group.serverProfiles[index]))
        newProfile.uuid = UUID().uuidString
        
        if group.isSubscription {
            addGroup(NSButton())
        }
        group = ServerGroupManager.serverGroups[groupsTableView.selectedRow]
        group.serverProfiles.insert(newProfile, at: 0)
        
        profilesTableView.beginUpdates()
        profilesTableView.insertRows(at: IndexSet(integer: 0), withAnimation: .effectFade)
        profilesTableView.endUpdates()
        
        profilesTableView.scrollRowToVisible(0)
        profilesTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        updateProfileBoxVisible()
    }
    
    @IBAction func addGroup(_ sender: NSButton) {
        let group = ServerGroup()
        group.groupName = "Default Group".localized
        ServerGroupManager.serverGroups.insert(group, at: 0)
        groupsTableView.beginUpdates()
        groupsTableView.insertRows(at: IndexSet(integer: 0), withAnimation: .effectFade)
        groupsTableView.endUpdates()
        groupsTableView.scrollRowToVisible(0)
        groupsTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }
    
    @IBAction func removeGroup(_ sender: NSButton) {
        let index = Int(groupsTableView.selectedRowIndexes.first!)
        var deleteCount = 0
        groupsTableView.beginUpdates()
        for toDeleteIndex in groupsTableView.selectedRowIndexes {
            if let activeProfile = ServerProfileManager.activeProfile {
                if activeProfile.groupId == ServerGroupManager.serverGroups[toDeleteIndex - deleteCount].groupId {
                    removedActiveProfile = true
                }
            }
            if loadBalanceGroup != nil && loadBalanceGroup?.groupId == ServerGroupManager.serverGroups[toDeleteIndex - deleteCount].groupId {
                loadBalanceGroup = nil
                loadBalanceProfiles = []
                loadBalanceProfilesChanged = true
            }
            ServerGroupManager.serverGroups[toDeleteIndex - deleteCount].serverProfiles = []
            ServerGroupManager.serverGroups.remove(at: toDeleteIndex - deleteCount)
            groupsTableView.removeRows(at: IndexSet(integer: toDeleteIndex - deleteCount), withAnimation: .effectFade)
            deleteCount += 1
        }
        groupsTableView.endUpdates()
        groupsTableView.scrollRowToVisible(index == 0 ? 0 : index - 1)
        groupsTableView.selectRowIndexes(IndexSet(integer: index == 0 ? 0 : index - 1), byExtendingSelection: false)
        profilesTableView.reloadData()
        updateProfileBoxVisible()
    }
    
    @IBAction func duplicateGroup(_ sender: NSButton) {
        if groupsTableView.selectedRowIndexes.count != 1 {
            return
        }
        let group = ServerGroupManager.serverGroups[groupsTableView.selectedRow]
        let newGroup = ServerGroup.fromDictionary(ServerGroup.toDictionary(group))
        newGroup.groupId = UUID().uuidString
        for item in newGroup.serverProfiles {
            item.uuid = UUID().uuidString
        }
        ServerGroupManager.serverGroups.insert(newGroup, at: 0)
        
        groupsTableView.beginUpdates()
        groupsTableView.insertRows(at: IndexSet(integer: 0), withAnimation: .effectFade)
        groupsTableView.endUpdates()
        
        groupsTableView.scrollRowToVisible(0)
        groupsTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        profilesTableView.reloadData()
        updateProfileBoxVisible()
    }
    
    @IBAction func ok(_ sender: NSButton) {
        if loadBalanceGroup != nil {
            UserDefaults.standard.set(ServerGroup.toDictionary(loadBalanceGroup!), forKey: UserKeys.LoadbalanceGroup)
        } else {
            UserDefaults.standard.removeObject(forKey: UserKeys.LoadbalanceGroup)
        }
        UserDefaults.standard.set(ServerProfile.toDictionaries(loadBalanceProfiles), forKey: UserKeys.LoadbalanceProfiles)
        if orderAddress.state == .on {
            UserDefaults.standard.set(true, forKey: UserKeys.OrderAddress)
            UserDefaults.standard.set(false, forKey: UserKeys.OrderRemark)
        } else {
            UserDefaults.standard.set(true, forKey: UserKeys.OrderRemark)
            UserDefaults.standard.set(false, forKey: UserKeys.OrderAddress)
        }
        ServerGroupManager.save()
        (NSApplication.shared.delegate as! AppDelegate).updateServersMenu()
        
        var updateMenu = false
        if loadBalanceGroup == nil {
            UserDefaults.standard.set(false, forKey: UserKeys.EnableLoadbalance)
            StopHaproxy()
            updateMenu = true
        } else {
            if loadBalanceProfiles.isEmpty {
                loadBalanceGroup = nil
                UserDefaults.standard.removeObject(forKey: UserKeys.LoadbalanceGroup)
                UserDefaults.standard.set(false, forKey: UserKeys.EnableLoadbalance)
                StopHaproxy()
                updateMenu = true
            } else if loadBalanceProfilesChanged {
                LoadBalance.enableLoadBalance()
            }
        }
        if removedActiveProfile {
            UserDefaults.standard.removeObject(forKey: UserKeys.ActiveServerProfile)
            ServerProfileManager.activeProfile = nil
            removeSSLocalConfFile()
            StopSSLocal()
            StopPrivoxy()
            (NSApplication.shared.delegate as! AppDelegate).updateSSAndPrivoxyServices()
            updateMenu = true
        }
        if updateMenu {
            (NSApplication.shared.delegate as! AppDelegate).updateServerMenuItemState()
            (NSApplication.shared.delegate as! AppDelegate).updateCommonMenuItemState()
        }
        window?.performClose(self)
    }
    
    @IBAction func cancel(_ sender: NSButton) {
        resetData()
        window?.performClose(self)
    }
    
    func resetData() {
        showPassword = false
        displayPassword(eyeButton)
        let p = defaults.array(forKey: UserKeys.ServerGroups)
        ServerGroupManager.serverGroups = ServerGroup.fromDictionaries(p as! [[String : AnyObject]])
        groupsTableView.reloadData()
        profilesTableView.reloadData()
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        resetData()
        return true
    }
    
    @IBAction func copyCurrentProfileURL2Pasteboard(_ sender: NSButton) {
        let index = profilesTableView.selectedRow
        if  index >= 0 {
            let profile = ServerGroupManager.serverGroups[groupsTableView.selectedRow].serverProfiles[index]
            let url = profile.URL()
            let pboard = NSPasteboard.general
            pboard.clearContents()
            let rs = pboard.writeObjects([url as NSPasteboardWriting])
            if rs {
                NSLog("copy to pasteboard success")
            } else {
                NSLog("copy to pasteboard failed")
            }
        }
    }
    
    @IBAction func displayPassword(_ sender: NSButton) {
        if showPassword {
            sender.image = NSImage(named: "eye_open")
            pwdTextField.isHidden = false
            passwordTextField.isHidden = true
            showPassword = false
        } else {
            sender.image = NSImage(named: "eye_close")
            pwdTextField.isHidden = true
            passwordTextField.isHidden = false
            showPassword = true
        }
    }
    
    func updateProfileBoxVisible() {
        if ServerGroupManager.serverGroups.isEmpty {
            removeGroupButton.isEnabled = false
            duplicateGroupButton.isEnabled = false
            removeProfileButton.isEnabled = false
            duplicateProfileButton.isEnabled = false
            profileBox.isHidden = true
        } else {
            removeGroupButton.isEnabled = true
            duplicateGroupButton.isEnabled = true
            if ServerGroupManager.serverGroups[groupsTableView.selectedRow].serverProfiles.isEmpty {
                removeProfileButton.isEnabled = false
                duplicateProfileButton.isEnabled = false
                profileBox.isHidden = true
            } else {
                removeProfileButton.isEnabled = true
                duplicateProfileButton.isEnabled = true
                profileBox.isHidden = false
            }
        }
    }
    
    func bindProfile(_ groupIndex: Int, _ serverIndex: Int) {
        if ServerGroupManager.serverGroups.isEmpty || ServerGroupManager.serverGroups[groupIndex].serverProfiles.isEmpty {
            updateProfileBoxVisible()
            return
        }
        
        editingProfile = ServerGroupManager.serverGroups[groupIndex < 0 ? 0 : groupIndex].serverProfiles[serverIndex < 0 ? 0 : serverIndex]
        
        hostTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "serverHost", options: [NSBindingOption.continuouslyUpdatesValue: true])
        portTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "serverPort", options: [NSBindingOption.continuouslyUpdatesValue: true])
        methodTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "method", options: [NSBindingOption.continuouslyUpdatesValue: true])
        passwordTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "password", options: [NSBindingOption.continuouslyUpdatesValue: true])
        remarkTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "remark", options: [NSBindingOption.continuouslyUpdatesValue: true])
        ProtocolTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "xProtocol", options: [NSBindingOption.continuouslyUpdatesValue: true])
        ProtocolParamTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "xProtocolParam", options: [NSBindingOption.continuouslyUpdatesValue: true])
        ObfsTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "obfs", options: [NSBindingOption.continuouslyUpdatesValue: true])
        ObfsParamTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "obfsParam", options: [NSBindingOption.continuouslyUpdatesValue: true])
        groupTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "group", options: [NSBindingOption.continuouslyUpdatesValue: true])
    
        pwdTextField.bind(NSBindingName(rawValue: "value"), to: editingProfile!, withKeyPath: "password", options: [NSBindingOption.continuouslyUpdatesValue: true])
    
        urlTextField.stringValue = editingProfile!.URL()
    }
    
    //--------------------------------------------------
    // MARK: For NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == groupsTableView {
            return ServerGroupManager.serverGroups.count
        } else {
            if ServerGroupManager.serverGroups.isEmpty {
                return 0
            }
            let index = groupsTableView.selectedRow == -1 ? 0 : groupsTableView.selectedRow
            return ServerGroupManager.serverGroups[index].serverProfiles.count
        }
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let (title, isActive) = getDataAtRow(tableView, row)
        if tableView == groupsTableView {
            if (tableColumn?.identifier)!.rawValue == "groupMain" {
                return title
            } else if (tableColumn?.identifier)!.rawValue == "groupStatus" {
                return isActive ? NSImage(named: "NSMenuOnStateTemplate") : nil
            }
        } else {
            if (tableColumn?.identifier)!.rawValue == "serverMain" {
                return title
            } else if (tableColumn?.identifier)!.rawValue == "serverStatus" {
                return isActive ? NSImage(named: "NSMenuOnStateTemplate") : nil
            }
        }
        return ""
    }
    
    func getDataAtRow(_ tableView: NSTableView, _ index: Int) -> (String, Bool) {
        let activeProfile = ServerProfileManager.activeProfile
        var isActive = false
        if tableView == groupsTableView {
            if UserDefaults.standard.bool(forKey: UserKeys.EnableLoadbalance) {
                isActive = LoadBalance.getLoadBalanceGroup()!.groupId == ServerGroupManager.serverGroups[index].groupId
            } else if activeProfile != nil {
                isActive = ServerGroupManager.serverGroups[index].groupId == activeProfile!.groupId
            }
            return (ServerGroupManager.serverGroups[index].groupName, isActive)
        } else {
            let profiles = ServerGroupManager.serverGroups[groupsTableView.selectedRow].serverProfiles
            if profiles.isEmpty {
                return ("", false)
            }
            let profile = profiles[profiles.count > index ? index : 0]
            if UserDefaults.standard.bool(forKey: UserKeys.EnableLoadbalance) {
                if UserDefaults.standard.bool(forKey: UserKeys.LoadbalanceEnableAllNodes) {
                    if LoadBalance.getLoadBalanceGroup()!.groupId == profile.groupId {
                        isActive = true
                    }
                } else {
                    isActive = LoadBalance.getLoadBalanceProfiles().filter({$0.getValidId() == profile.getValidId()}).count > 0
                }
            } else if activeProfile != nil && !removedActiveProfile {
                isActive = activeProfile?.getValidId() == profile.getValidId()
            }
            return (profile.remark.isEmpty ? profile.serverHost : profile.remark, isActive)
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if groupsTableView.selectedRow == -1 {
            return
        }
        profilesTableView.reloadData()
        showPassword = false
        displayPassword(eyeButton)
        bindProfile(groupsTableView.selectedRow, profilesTableView.selectedRow)
        updateProfileBoxVisible()
        if groupsTableView.selectedRowIndexes.count > 1 {
            duplicateGroupButton.isEnabled = false
        }
        if profilesTableView.selectedRowIndexes.count > 1 {
            duplicateProfileButton.isEnabled = false
        }
    }
    
    // For NSTableViewDelegate
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return tableView == groupsTableView ? true : false
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let tView = obj.object as? NSTableView {
            let index = tView.editedRow
            if index < 0 {
                return
            }
            if let title = tView.currentEditor() {
                ServerGroupManager.serverGroups[index].groupName = title.string
            }
        }
    }
    
    @IBAction func order(_ sender: NSButton) {
        
    }
}
