//
//  AdvPreferencesWindowController.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa

class AdvPreferencesWindowController: NSWindowController, NSWindowDelegate {
    
    @IBOutlet weak var warnTextField: NSTextField!
    
    var keys: [String : String] = [:]
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.window?.delegate = self
        initKeys()
        keyLocalize()
    }
    
    func initKeys() {
        self.window!.setAccessibilityValueDescription(self.window!.title)
        keys[self.window!.title] = self.window!.title
        for item in warnTextField.superview!.subviews {
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
        for item in warnTextField.superview!.subviews {
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
    
    @IBAction func ok(_ sender: NSButton) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIFY_ADV_CONF_CHANGED), object: nil)
        window?.performClose(self)
    }
    
    @IBAction func cancel(_ sender: NSButton) {
        window?.performClose(self)
    }
    
}
