//
//  ShowExampleConfigController.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix on 2019/8/7.
//  Copyright © 2019 felix.xu. All rights reserved.
//

class ShowExampleConfigController: NSWindowController {
    @IBOutlet weak var textView: NSTextView!
    
    let filePath: String = Bundle.main.path(forResource: "example-gui-config", ofType: "json")!
    let fileMgr = FileManager.default
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.title = "Example Configuration".localized
        showExampleConfig()
    }
    
    func showExampleConfig() {
        if fileMgr.isReadableFile(atPath: filePath) {
            textView.string = try! String(contentsOfFile: filePath)
        } else {
            textView.textStorage?.append(NSAttributedString(string: ""))
        }
    }
    
    func downloadExampleConfig() {
        let dataPath = NSHomeDirectory() + "/Downloads"
        let destPath = dataPath + "/example-gui-config.json"
        //检测文件是否已经存在，如果存在直接用sharedWorkspace显示
        if fileMgr.fileExists(atPath: destPath) {
            NSWorkspace.shared.selectFile(destPath, inFileViewerRootedAtPath: dataPath)
        }else{
            try! fileMgr.copyItem(atPath: filePath, toPath: destPath)
            NSWorkspace.shared.selectFile(destPath, inFileViewerRootedAtPath: dataPath)
        }
    }
}
