//
//  LoadBalancePreferenceController.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix on 2019/8/16.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation

class LoadBalancePreferenceController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var subscriptionsBox: NSComboBox!
    @IBOutlet weak var strategyBox: NSComboBox!
    @IBOutlet weak var allNodesButton: NSButton!
    @IBOutlet weak var nodesTableView: NSTableView!
    
    var keys: [String : String] = [:]
    var subscriptions: [ServerGroup] = []
    var loadbalanceProfiles: [ServerProfile] = []
    var loadbalanceGroup: ServerGroup?
    var loadbalanceStrategy: String?
    
    override func windowWillLoad() {
        subscriptions = ServerGroupManager.getSubscriptions()
        loadbalanceGroup = LoadBalance.getLoadBalanceGroup()
        loadbalanceProfiles = LoadBalance.getLoadBalanceProfiles()
        if let strategy = UserDefaults.standard.string(forKey: UserKeys.LoadbalanceStrategy) {
            loadbalanceStrategy = strategy
        } else {
            loadbalanceStrategy = LoadBalance.strategies[0].0
        }
    }
    
    override func windowDidLoad() {
        for (index, item) in subscriptions.enumerated() {
            subscriptionsBox.addItem(withObjectValue: item.groupName)
            if loadbalanceGroup != nil && item.groupId == loadbalanceGroup!.groupId{
                subscriptionsBox.selectItem(at: index)
            }
        }
        if loadbalanceGroup == nil {
            subscriptionsBox.selectItem(at: 0)
            loadbalanceGroup = subscriptions[0]
        }
        strategyBox.addItems(withObjectValues: LoadBalance.strategies.map({$0.1.localized}))
        if loadbalanceStrategy == nil {
            strategyBox.selectItem(at: 0)
            loadbalanceStrategy = LoadBalance.strategies[0].0
        }
        if UserDefaults.standard.bool(forKey: UserKeys.LoadbalanceEnableAllNodes) {
            allNodesButton.state = NSControl.StateValue(rawValue: 1)
            nodesTableView.isEnabled = false
        } else {
            allNodesButton.state = NSControl.StateValue(rawValue: 0)
            nodesTableView.isEnabled = true
        }
        for (index, item) in LoadBalance.strategies.enumerated() {
            if item.0 == loadbalanceStrategy {
                strategyBox.selectItem(at: index)
            }
        }
        initKeys()
        keyLocalize()
        nodesTableView.reloadData()
    }
    
    func initKeys() {
        self.window!.setAccessibilityValueDescription(self.window!.title)
        keys[self.window!.title] = self.window!.title
        for item in subscriptionsBox.superview!.subviews {
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
        for item in subscriptionsBox.superview!.subviews {
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
    
    @IBAction func onOk(_ sender: NSButton) {
        let defaults = UserDefaults.standard
        defaults.set(ServerGroup.toDictionary(loadbalanceGroup!), forKey: UserKeys.LoadbalanceGroup)
        loadbalanceProfiles.removeAll(where: {$0.groupId != loadbalanceGroup?.groupId})
        defaults.set(ServerProfile.toDictionaries(loadbalanceProfiles), forKey: UserKeys.LoadbalanceProfiles)
        defaults.set(allNodesButton.state.rawValue == 1 ? true : false, forKey: UserKeys.LoadbalanceEnableAllNodes)
        defaults.set(loadbalanceStrategy, forKey: UserKeys.LoadbalanceStrategy)
        DispatchQueue.global().async {
            setupProxy()
            DispatchQueue.main.async {
                (NSApplication.shared.delegate as! AppDelegate).updateServersMenu()
                (NSApplication.shared.delegate as! AppDelegate).updateServerMenuItemState()
            }
        }
        window?.performClose(self)
    }
    
    @IBAction func cancel(_ sender: NSButton) {
        window?.performClose(self)
    }
    
    @IBAction func groupChange(_ sender: NSComboBox) {
        loadbalanceGroup = subscriptions[sender.indexOfSelectedItem]
        nodesTableView.reloadData()
    }
    
    @IBAction func allNodesEnableChange(_ sender: NSButton) {
        nodesTableView.isEnabled = sender.state.rawValue == 1 ? false : true
    }
    
    @IBAction func strategyChange(_ sender: NSComboBox) {
        loadbalanceStrategy = LoadBalance.strategies[sender.indexOfSelectedItem].0
    }
    
    @IBAction func onClick(_ sender: NSTableView) {
        if subscriptions.isEmpty || nodesTableView.selectedRow <= 0 {
            return
        }
        let group = subscriptions[subscriptionsBox.indexOfSelectedItem]
        let profile = group.serverProfiles[nodesTableView.selectedRow]
        if loadbalanceProfiles.filter({$0.hashVal == profile.hashVal}).isEmpty {
            loadbalanceProfiles.append(profile)
        } else {
            loadbalanceProfiles.removeAll(where: {$0.hashVal == profile.hashVal})
        }
        nodesTableView.reloadData(forRowIndexes: IndexSet(integer: nodesTableView.selectedRow), columnIndexes: IndexSet(integer: 0))
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let profile = subscriptions[subscriptionsBox.indexOfSelectedItem].serverProfiles[row]
        if (tableColumn?.identifier)!.rawValue == "main" {
            return profile.remark
        } else if (tableColumn?.identifier)!.rawValue == "status" && loadbalanceProfiles.contains(where: {$0.hashVal == profile.hashVal}) {
            return NSImage(named: "NSStatusAvailable")
        }
        return nil
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if subscriptions.isEmpty || subscriptionsBox.indexOfSelectedItem == -1 {
            return 0
        }
        return subscriptions[subscriptionsBox.indexOfSelectedItem].serverProfiles.count
    }
    
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return false
    }
}
