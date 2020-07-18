//
//  UserRulesController.swift
//  ShadowsocksX-NG
//
//  Created by 周斌佳 on 16/8/1.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa

class UserRulesController: NSWindowController {

    @IBOutlet var userRulesView: NSTextView!
    @IBOutlet var okButton: NSButton!
    @IBOutlet var cancelButton: NSButton!

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.title = "User Rules".localized
        okButton.title = "OK".localized
        cancelButton.title = "Cancel".localized
        let fileMgr = FileManager.default
        if !fileMgr.fileExists(atPath: PACUserRuleFilePath) {
            let src = Bundle.main.path(forResource: "user-rule", ofType: "txt")
            try! fileMgr.copyItem(atPath: src!, toPath: PACUserRuleFilePath)
        }

        let str = try? String(contentsOfFile: PACUserRuleFilePath, encoding: String.Encoding.utf8)
        userRulesView.string = str!
    }
    
    @IBAction func didCancel(_ sender: AnyObject) {
        window?.performClose(self)
    }

    @IBAction func didOK(_ sender: AnyObject) {
        if let str = userRulesView?.string {
            do {
                try str.data(using: String.Encoding.utf8)?.write(to: URL(fileURLWithPath: PACUserRuleFilePath), options: .atomic)
                if GeneratePACFile() {
                    stopPACServer()
                    _ = startPACServer()
                    notificationDeliver(title: "User's PAC rule updated", subTitle: "", text: "")
                } else {
                    notificationDeliver(title: "Failed update PAC rule for User", subTitle: "", text: "")
                }
            } catch {
                NSLog("Write user rule failed")
            }
        }
        window?.performClose(self)
    }
}
