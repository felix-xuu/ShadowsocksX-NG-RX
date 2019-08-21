//
//  AppDelegate.swift
//  LaunchHelper
//
//  Created by Felix on 2019/8/8.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let mainAppId = "com.felix.xu.ShadowsocksX-NG-RX"
        let running   = NSWorkspace.shared.runningApplications
        for app in running {
            if app.bundleIdentifier == mainAppId {
                return
            }
        }
        let path = Bundle.main.bundlePath as NSString
        var components = path.pathComponents
        components.removeLast()
        components.removeLast()
        components.removeLast()
        components.append("MacOS")
        components.append("ShadowsocksX-NG-RX")
        
        let newPath = NSString.path(withComponents: components)
        NSWorkspace.shared.launchApplication(newPath)
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

