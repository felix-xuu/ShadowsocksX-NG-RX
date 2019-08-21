//
//  ProxyPreferencesController.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/29.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa

class ProxyPreferencesController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    
    var networkServices: NSArray!
    var selectedNetworkServices: NSMutableSet!
    
    @objc dynamic var autoConfigureNetworkServices: Bool = true
    
    @IBOutlet var tableView: NSTableView!
    
    var keys: [String : String] = [:]

    override func windowDidLoad() {
        super.windowDidLoad()
        initKeys()
        keyLocalize()

        let defaults = UserDefaults.standard
        self.setValue(defaults.bool(forKey: UserKeys.AutoConfigureNetworkServices), forKey: UserKeys.AutoConfigureNetworkServices)
        
        if let services = defaults.array(forKey: UserKeys.Proxy4NetworkServices) {
            selectedNetworkServices = NSMutableSet(array: services)
        } else {
            selectedNetworkServices = NSMutableSet()
        }
        
        networkServices = ProxyConfTool.networkServicesList() as NSArray
        tableView.reloadData()
    }
    
    func initKeys() {
        self.window!.setAccessibilityValueDescription(self.window!.title)
        keys[self.window!.title] = self.window!.title
        for item in self.window!.contentView!.subviews {
            if item.tag == 1 && item is NSButton {
                let button = item as! NSButton
                button.setAccessibilityValueDescription(button.title)
                keys[button.title] = button.title
            }
        }
    }
    
    func keyLocalize() {
        self.window!.title = keys[self.window!.accessibilityValueDescription()!]!.localized
        for item in self.window!.contentView!.subviews {
            if item.tag == 1 && item is NSButton {
                let button = item as! NSButton
                button.title = keys[button.accessibilityValueDescription()!]!.localized
            }
        }
    }
    
    @IBAction func ok(_ sender: NSObject){
        let defaults = UserDefaults.standard
        defaults.setValue(selectedNetworkServices.allObjects, forKeyPath: UserKeys.Proxy4NetworkServices)
        defaults.set(autoConfigureNetworkServices, forKey: UserKeys.AutoConfigureNetworkServices)
        
        defaults.synchronize()
        
        window?.performClose(self)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIFY_ADV_PROXY_CONF_CHANGED), object: nil)
    }
    
    @IBAction func cancel(_ sender: NSObject){
        window?.performClose(self)
    }
    
    // For NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        if networkServices != nil {
            return networkServices.count
        }
        return 0;
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let cell = tableColumn!.dataCell as! NSButtonCell
        
        let key = (networkServices[row] as AnyObject)["key"] as! String
        if selectedNetworkServices.contains(key) {
            cell.state = NSControl.StateValue(rawValue: 1)
        } else {
            cell.state = NSControl.StateValue(rawValue: 0)
        }
        let userDefinedName = (networkServices[row] as AnyObject)["userDefinedName"] as! String
        cell.title = userDefinedName
        return cell
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?
        , for tableColumn: NSTableColumn?, row: Int) {
        let key = (networkServices[row] as AnyObject)["key"] as! String
        
        if (object! as AnyObject).intValue == 1 {
            selectedNetworkServices.add(key)
        } else {
            selectedNetworkServices.remove(key)
        }
    }
}
