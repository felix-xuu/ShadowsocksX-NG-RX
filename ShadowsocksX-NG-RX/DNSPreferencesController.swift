//
//  DNSPreferencesController.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2020/10/28.
//  Copyright © 2020 felix.xu. All rights reserved.
//

import Cocoa

class DNSPreferencesController: NSWindowController {
    @objc dynamic var enableDNS: Bool = false
    
    @IBOutlet var dnsServersView: NSTextView!
    
    var keys: [String : String] = [:]

    override func windowDidLoad() {
        super.windowDidLoad()
        initKeys()
        keyLocalize()

        let defaults = UserDefaults.standard
        enableDNS = defaults.bool(forKey: UserKeys.DNSEnable)
        dnsServersView.string = defaults.string(forKey: UserKeys.DNSServers) ?? ""
    }
    
    func initKeys() {
        self.window!.setAccessibilityValueDescription(self.window!.title)
        keys[self.window!.title] = self.window!.title
        for item in self.window!.contentView!.subviews {
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
        for item in self.window!.contentView!.subviews {
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
    
    @IBAction func ok(_ sender: NSObject){
        let serverArr = dnsServersView.string.components(separatedBy: [",", "\n"])
        for item in serverArr {
            let str = item.trimmingCharacters(in: .whitespacesAndNewlines)
            if str != "" && !validateIpAddress(ipToValidate: str) {
                let alert = NSAlert.init()
                alert.alertStyle = NSAlert.Style.warning
                alert.addButton(withTitle: "OK".localized)
                alert.messageText = "Warning".localized
                alert.informativeText = "Invalid IP Address".localized
                NSApp.activate(ignoringOtherApps: true)
                alert.runModal()
                return
            }
        }
        let defaults = UserDefaults.standard
        defaults.set(enableDNS, forKey: UserKeys.DNSEnable)
        defaults.set(dnsServersView.string, forKey: UserKeys.DNSServers)
        defaults.synchronize()
        
        window?.performClose(self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: DNS_CONF_CHANGED), object: nil)
    }
    
    @IBAction func cancel(_ sender: NSObject){
        window?.performClose(self)
    }
}
