//
//  NetWorkMonitor.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix on 2019/12/25.
//  Copyright © 2019 felix.xu. All rights reserved.
//

import Foundation

class NetWorkMonitor: NSObject {
    static let KB: Float = 1024
    static let MB: Float = KB * 1024
    static let GB: Float = MB * 1024
    static let TB: Float = GB * 1024
    
    var timer: DispatchSourceTimer?
    var lastOutbound: Float = 0.00
    var lastInbound: Float = 0.00
    
    func start() {
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.init(label: "shadowsocksX.netspeed"))
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        timer?.setEventHandler(handler: {
            self.updateNetWorkData()
        })
        timer?.resume()
    }
    
    func stop(){
        timer?.cancel()
        timer = nil
    }
    
    func updateNetWorkData() {
        if (timer != nil && timer!.isCancelled) || !Thread.main.isExecuting {
            return
        }
        let task = Process()
        task.launchPath = "/usr/bin/nettop"
        task.arguments = ["-x", "-P", "-L", "1", "-J", "bytes_in,bytes_out", "-t", "external"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        task.launch()
        task.waitUntilExit()
        let status = task.terminationStatus
         
        if status == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string = String(data: data, encoding: String.Encoding.utf8)
            handleNetWorkData(string!)
        } else {
            print("Task failed.")
        }
    }
    
    func handleNetWorkData(_ string: String) {
        var outbound: Float = 0.00
        var inbound: Float = 0.00
        let results = string.split(separator: "\n")
        for (index, result) in results.enumerated() {
            if index == 0 {
                continue
            }
            let temp = result.split(separator: ",")
            if temp.count == 3 {
                inbound += Float(temp[1])!
                outbound += Float(temp[2])!
            }
        }
        DispatchQueue.main.async {
            (NSApplication.shared.delegate as! AppDelegate).updateNetSpeed(inbound: self.formatData(inbound - self.lastInbound), outbound: self.formatData(outbound - self.lastOutbound))
            self.lastInbound = inbound
            self.lastOutbound = outbound
        }
    }
    
    func formatData(_ data: Float) -> String {
        var result: Float
        var unit: String
        
        if data < NetWorkMonitor.KB {
            result = 0
            unit = " KB/s"
        } else if data < NetWorkMonitor.MB {
            result = data/NetWorkMonitor.KB
            unit = " KB/s"
        } else if data < NetWorkMonitor.GB {
            result = data/NetWorkMonitor.MB
            unit = " MB/s"
        } else if data < NetWorkMonitor.TB {
            result = data/NetWorkMonitor.GB
            unit = " GB/s"
        } else {
            result = data/NetWorkMonitor.TB
            unit = " TB/s"
        }
        return "\(String(format: "%0.2f", result))\(unit)"
    }
}
