//
//  SubscribePreferenceWindowController.swift
//  ShadowsocksX-NG
//
//  Created by 秦宇航 on 2017/6/15.
//  Copyright © 2017年 qiuyuzhou. All rights reserved.
//

import Cocoa

class SubscribePreferenceWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var OKButton: NSButton!

    @IBOutlet weak var autoUpdateButton: NSButton!
    @IBOutlet weak var UrlTextField: NSTextField!
    @IBOutlet weak var TokenTextField: NSTextField!
    @IBOutlet weak var GroupTextField: NSTextField!
    @IBOutlet weak var MaxCountTextField: NSTextField!
    @IBOutlet weak var SubscribeTableView: NSTableView!

    @IBOutlet weak var AddSubscribeBtn: NSButton!
    @IBOutlet weak var DeleteSubscribeBtn: NSButton!
    
    var defaults: UserDefaults!
    var editingSubscribe: ServerGroup!
    var subscriptions: [ServerGroup]!
    var loadBalanceGroup: ServerGroup?
    var loadBalanceProfiles: [ServerProfile]!
    
    var keys: [String : String] = [:]
    
    override func windowWillLoad() {
        defaults = UserDefaults.standard
        subscriptions = ServerGroupManager.getSubscriptions()
        loadBalanceGroup = LoadBalance.getLoadBalanceGroup()
        loadBalanceProfiles = LoadBalance.getLoadBalanceProfiles()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        SubscribeTableView.reloadData()
        updateSubscribeBoxVisible()
        bindSubscribe(0)
        initKeys()
        keyLocalize()
    }
    
    func initKeys() {
        self.window!.setAccessibilityValueDescription(self.window!.title)
        keys[self.window!.title] = self.window!.title
        for item in UrlTextField.superview!.subviews {
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
        for item in UrlTextField.superview!.subviews {
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
        SubscribeTableView.allowsMultipleSelection = true
    }
    
    @IBAction func onOk(_ sender: NSButton) {
        if loadBalanceGroup != nil {
            UserDefaults.standard.set(ServerGroup.toDictionary(loadBalanceGroup!), forKey: UserKeys.LoadbalanceGroup)
        }
        UserDefaults.standard.set(ServerProfile.toDictionaries(loadBalanceProfiles), forKey: UserKeys.LoadbalanceProfiles)
        if loadBalanceGroup == nil && UserDefaults.standard.bool(forKey: UserKeys.EnableLoadbalance) {
            UserDefaults.standard.set(false, forKey: UserKeys.EnableLoadbalance)
            StopHaproxy()
            (NSApplication.shared.delegate as! AppDelegate).updateSSAndPrivoxyServices()
            (NSApplication.shared.delegate as! AppDelegate).updateCommonMenuItemState()
        }
        ServerGroupManager.save()
        SubscribeManager.autoUpdateCount = 0
        window?.performClose(self)
        DispatchQueue.global().async {
            ServerGroupManager.getSubscriptions().forEach({ value in
                if value.autoUpdate {
                    SubscribeManager.updateServerFromSubscription(value)
                }
            })
            while SubscribeManager.autoUpdateCount != self.subscriptions.filter({$0.autoUpdate}).count {
                usleep(100000)
            }
            DispatchQueue.main.async {
                ServerGroupManager.save()
                (NSApplication.shared.delegate as! AppDelegate).updateServersMenu()
                (NSApplication.shared.delegate as! AppDelegate).updateServerMenuItemState()
                SubscribeManager.autoUpdateCount = -1
            }
        }
    }
    
    @IBAction func cancel(_ sender: NSButton) {
        resetData()
        window?.performClose(self)
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        resetData()
        return true
    }
    
    func resetData() {
        ServerGroupManager.serverGroups = ServerGroup.fromDictionaries(defaults.array(forKey: UserKeys.ServerGroups) as! [[String : AnyObject]])
        SubscribeTableView.reloadData()
    }
    
    @IBAction func onAdd(_ sender: NSButton) {
        SubscribeTableView.beginUpdates()
        let subscription = ServerGroup()
        subscription.isSubscription = true
        subscription.groupName = "Default Group".localized
        subscriptions.insert(subscription, at: 0)
        ServerGroupManager.serverGroups.insert(subscription, at: 0)
        
        SubscribeTableView.insertRows(at: IndexSet(integer: 0), withAnimation: .effectFade)
        
        SubscribeTableView.scrollRowToVisible(0)
        SubscribeTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        SubscribeTableView.endUpdates()
        updateSubscribeBoxVisible()
    }
    
    @IBAction func onDelete(_ sender: NSButton) {
        let index = Int(SubscribeTableView.selectedRowIndexes.first!)
        var deleteCount = 0
        SubscribeTableView.beginUpdates()
        for toDeleteIndex in SubscribeTableView.selectedRowIndexes {
            ServerGroupManager.serverGroups.removeAll(where: {$0.groupId == subscriptions[toDeleteIndex - deleteCount].groupId})
            if let p = ServerProfileManager.activeProfile {
                if p.groupId == subscriptions[toDeleteIndex - deleteCount].groupId {
                    ServerProfileManager.activeProfile = nil
                }
            }
            if loadBalanceGroup != nil && subscriptions[toDeleteIndex - deleteCount].groupId == loadBalanceGroup?.groupId {
                loadBalanceGroup = nil
                loadBalanceProfiles = []
            }
            subscriptions.remove(at: toDeleteIndex - deleteCount)
            SubscribeTableView.removeRows(at: IndexSet(integer: toDeleteIndex - deleteCount), withAnimation: .effectFade)
            deleteCount += 1
        }
        SubscribeTableView.scrollRowToVisible(index == 0 ? 0 : index - 1)
        SubscribeTableView.selectRowIndexes(IndexSet(integer: index == 0 ? 0 : index - 1), byExtendingSelection: false)
        SubscribeTableView.endUpdates()
        updateSubscribeBoxVisible()
    }
    
    func cleanField(){
        UrlTextField.stringValue = ""
        TokenTextField.stringValue = ""
        GroupTextField.stringValue = ""
        MaxCountTextField.stringValue = ""
    }
    
    func updateSubscribeBoxVisible() {
        if subscriptions.isEmpty {
            DeleteSubscribeBtn.isEnabled = false
            UrlTextField.isEnabled = false
            TokenTextField.isEnabled = false
            GroupTextField.isEnabled = false
            MaxCountTextField.isEnabled = false
            cleanField()
        } else {
            DeleteSubscribeBtn.isEnabled = true
            UrlTextField.isEnabled = true
            TokenTextField.isEnabled = true
            GroupTextField.isEnabled = true
            MaxCountTextField.isEnabled = true
        }
    }
    
    func bindSubscribe(_ index:Int) {
        if subscriptions.isEmpty {
            updateSubscribeBoxVisible()
            return
        }
        editingSubscribe = subscriptions[index]
        
        UrlTextField.bind(NSBindingName(rawValue: "value"), to: editingSubscribe!, withKeyPath: "subscribeUrl", options: [NSBindingOption.continuouslyUpdatesValue: true])
        TokenTextField.bind(NSBindingName(rawValue: "value"), to: editingSubscribe!, withKeyPath: "token", options: [NSBindingOption.continuouslyUpdatesValue: true])
        GroupTextField.bind(NSBindingName(rawValue: "value"), to: editingSubscribe!, withKeyPath: "groupName", options: [NSBindingOption.continuouslyUpdatesValue: true])
        MaxCountTextField.bind(NSBindingName(rawValue: "value"), to: editingSubscribe!, withKeyPath: "maxCount", options: [NSBindingOption.continuouslyUpdatesValue: true])
        autoUpdateButton.bind(NSBindingName(rawValue: "value"), to: editingSubscribe!, withKeyPath: "autoUpdate", options: [NSBindingOption.continuouslyUpdatesValue: true])
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        bindSubscribe(SubscribeTableView.selectedRow)
    }
    
    // MARK: For NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return subscriptions.count
    }
    
    func getDataAtRow(_ index:Int) -> String {
        return subscriptions[index].groupName
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let title = getDataAtRow(row)
        
        if (tableColumn?.identifier)!.rawValue == "main" {
            return title
        } else if (tableColumn?.identifier)!.rawValue == "status" {
            return NSImage(named: "NSToolbarBookmarks")
        }
        return ""
    }
    
    // For NSTableViewDelegate
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return false
    }
    
}
