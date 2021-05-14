//
//  RuleController.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2021/4/17.
//  Copyright © 2021 felix.xu. All rights reserved.
//

import Cocoa

class RuleController: NSWindowController {
    @IBOutlet var rulesView: NSTextView!
    
    var keys: [String : String] = [:]

    override func windowDidLoad() {
        super.windowDidLoad()
        initKeys()
        keyLocalize()
        let defaults = UserDefaults.standard
        rulesView.string = defaults.string(forKey: UserKeys.BypassRulesText) ?? ""
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
        let ruleArr = rulesView.string.components(separatedBy: ["\n"])
        var validRules:[String] = []
        for item in ruleArr {
            let str = item.trimmingCharacters(in: .whitespacesAndNewlines)
            if str != "" {
                let regex = try? NSRegularExpression(pattern: str, options: [NSRegularExpression.Options.caseInsensitive])
                if regex == nil {
                    let alert = NSAlert.init()
                    alert.alertStyle = NSAlert.Style.warning
                    alert.addButton(withTitle: "OK".localized)
                    alert.messageText = "Warning".localized
                    alert.informativeText = "Invalid Text: \(str)"
                    NSApp.activate(ignoringOtherApps: true)
                    alert.runModal()
                    return
                }
                validRules.append(str)
            }
        }
        writeRules(rules: validRules)
        let defaults = UserDefaults.standard
        defaults.set(rulesView.string, forKey: UserKeys.BypassRulesText)
        defaults.set(validRules, forKey: UserKeys.BypassRules)
        defaults.synchronize()
        ReloadConfSSLocal()
        window?.performClose(self)
    }
    
    @IBAction func cancel(_ sender: NSObject){
        window?.performClose(self)
    }
}

