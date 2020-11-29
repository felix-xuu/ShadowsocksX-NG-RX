//
//  RuleConfigPreferenceController.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2020/11/28.
//  Copyright © 2020 felix.xu. All rights reserved.
//

import Cocoa

class RuleConfigPreferenceController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var profilesTableView: NSTableView!
    @IBOutlet weak var rulesTableView: NSTableView!
    @IBOutlet weak var ruleTextView: NSTextView!
    @IBOutlet weak var subscriptionsBox: NSComboBox!
    @IBOutlet weak var direct: NSButton!
    @IBOutlet weak var proxy: NSButton!
    @IBOutlet weak var ruleStatusColumn: NSTableColumn!
    
    var keys: [String : String] = [:]
    var subscriptions: [ServerGroup] = []
    var ruleGroup: ServerGroup?
    var ruleConfigs: [RuleConfig] = []
    
    override func windowWillLoad() {
        subscriptions = ServerGroupManager.getSubscriptions()
        ruleConfigs = RuleManager.getRuleConfigs() ?? []
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        let defaults = UserDefaults.standard
        if defaults.string(forKey: UserKeys.RuleDefaultFlow) == "direct" {
            direct.state = .on
            proxy.state = .off
        } else {
            direct.state = .off
            proxy.state = .on
        }
        for (index, item) in subscriptions.enumerated() {
            subscriptionsBox.addItem(withObjectValue: item.groupName)
            if ServerProfileManager.activeProfile?.groupId == item.groupId {
                subscriptionsBox.selectItem(at: index)
                ruleGroup = item
            }
        }
        if ruleGroup == nil && !subscriptions.isEmpty {
            subscriptionsBox.selectItem(at: 0)
            ruleGroup = subscriptions[0]
        }
        rulesTableView.reloadData()
        profilesTableView.reloadData()
        initKeys()
        keyLocalize()
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
    
    @IBAction func addRule(_ sender: NSButton) {
        rulesTableView.beginUpdates()
        let rule = RuleConfig()
        rule.enable = true
        rule.name = "Rule Name"
        rule.rules = "#Only IPV4, IPV6 and CIDR supported\n"
        ruleConfigs.insert(rule, at: 0)
        
        rulesTableView.insertRows(at: IndexSet(integer: 0), withAnimation: .effectFade)
        rulesTableView.scrollRowToVisible(0)
        rulesTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        rulesTableView.endUpdates()
        profilesTableView.reloadData()
    }
    
    @IBAction func removeRule(_ sender: NSButton) {
        rulesTableView.beginUpdates()
        let selectedRow = rulesTableView.selectedRow
        rulesTableView.removeRows(at: IndexSet(integer: selectedRow), withAnimation: .effectFade)
        ruleConfigs.remove(at: selectedRow)
        rulesTableView.scrollRowToVisible(selectedRow == 0 ? 0 : selectedRow - 1)
        rulesTableView.selectRowIndexes(IndexSet(integer: selectedRow == 0 ? 0 : selectedRow - 1), byExtendingSelection: false)
        rulesTableView.endUpdates()
        profilesTableView.reloadData()
    }
    
    @IBAction func ok(_ sender: NSButton) {
        let defaults = UserDefaults.standard
        if direct.state == .on {
            defaults.set("direct", forKey: UserKeys.RuleDefaultFlow)
        } else {
            defaults.set("proxy", forKey: UserKeys.RuleDefaultFlow)
        }
        defaults.set(RuleConfig.toDictionaries(ruleConfigs), forKey: UserKeys.RuleConfigs)
        window?.performClose(self)
    }
    
    @IBAction func cancel(_ sender: NSButton) {
        window?.performClose(self)
    }
    
    @IBAction func onClickRule(_ sender: NSTableView) {
        if ruleConfigs.isEmpty {
            return
        }
        if rulesTableView.clickedColumn == 0 {
            ruleConfigs[rulesTableView.selectedRow].enable = !ruleConfigs[rulesTableView.selectedRow].enable
            rulesTableView.reloadData(forRowIndexes: IndexSet(integer: rulesTableView.selectedRow), columnIndexes: IndexSet(integer: 0))
        }
        profilesTableView.reloadData()
    }
    
    @IBAction func onClickProfile(_ sender: NSTableView) {
        if ruleGroup == nil || ruleConfigs.isEmpty || profilesTableView.selectedRow < 0 {
            return
        }
        let profile = ruleGroup!.serverProfiles[profilesTableView.selectedRow]
        ruleConfigs[rulesTableView.selectedRow].profile = profile
        profilesTableView.reloadData()
    }
    
    @IBAction func groupChange(_ sender: NSComboBox) {
        ruleGroup = subscriptions[sender.indexOfSelectedItem]
        profilesTableView.reloadData()
    }
    
    //--------------------------------------------------
    // MARK: For NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == rulesTableView {
            return ruleConfigs.count
        } else {
            return ruleGroup?.serverProfiles.count ?? 0
        }
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let (title, isActive) = getDataAtRow(tableView, row)
        if tableView == rulesTableView {
            if (tableColumn?.identifier)!.rawValue == "groupMain" {
                return title
            } else if (tableColumn?.identifier)!.rawValue == "groupStatus" {
                return isActive ? NSImage(named: "NSStatusAvailable") : nil
            }
        } else {
            if (tableColumn?.identifier)!.rawValue == "serverMain" {
                return title
            } else if (tableColumn?.identifier)!.rawValue == "serverStatus" {
                return isActive ? NSImage(named: "NSStatusAvailable") : nil
            }
        }
        return nil
    }
    
    func getDataAtRow(_ tableView: NSTableView, _ index: Int) -> (String, Bool) {
        if tableView == rulesTableView {
            return (ruleConfigs[index].name, ruleConfigs[index].enable)
        } else {
            let profiles = ruleGroup?.serverProfiles ?? []
            if profiles.isEmpty {
                return ("", false)
            }
            let profile = profiles[index]
            var isActive = false
            if !ruleConfigs.isEmpty && profile.hashVal == ruleConfigs[rulesTableView.selectedRow].profile?.hashVal {
                isActive = true
            }
            return (profile.remark.isEmpty ? profile.serverHost : profile.remark, isActive)
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if rulesTableView.selectedRow < 0 {
            return
        }
        ruleTextView.bind(NSBindingName(rawValue: "value"), to: ruleConfigs[rulesTableView.selectedRow], withKeyPath: "rules", options: [NSBindingOption.continuouslyUpdatesValue: true])
        ruleTextView.string = ruleConfigs[rulesTableView.selectedRow].rules
    }
    
    // For NSTableViewDelegate
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return tableView == rulesTableView ? true : false
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let tView = obj.object as? NSTableView {
            let index = tView.editedRow
            if index < 0 {
                return
            }
            if let title = tView.currentEditor() {
                ruleConfigs[index].name = title.string
            }
        }
    }
    
    @IBAction func defaultFlow(_ sender: NSButton) {
    }
}
