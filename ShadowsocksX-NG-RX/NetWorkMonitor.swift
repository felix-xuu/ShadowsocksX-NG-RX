//
//  MonitorTask.swift
//  Up&Down
//
//  Created by 郭佳哲 on 6/3/16.
//  Copyright © 2016 郭佳哲. All rights reserved.
//

import Foundation

class NetWorkMonitor: NSObject {
    static let KB: Float = 1024
    static let MB: Float = KB * 1024
    static let GB: Float = MB * 1024
    static let TB: Float = GB * 1024
    
    var thread: Thread?
    var timer: Timer?
    var lastOutbound: Float = 0.00
    var lastInbound: Float = 0.00
    
    func start() {
        if thread != nil && thread!.isExecuting {
            return
        }
        thread = Thread(target: self, selector: #selector(startUpdateTimer), object: nil)
        thread?.start()
    }
    
    @objc func startUpdateTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateNetWorkData), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
        RunLoop.current.run()
    }
    
    func stop(){
        thread?.cancel()
    }
    
    @objc func updateNetWorkData() {
        if Thread.current.isCancelled {
            timer?.invalidate()
            timer = nil
            thread = nil
            Thread.exit()
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
            let fileHandle = pipe.fileHandleForReading
            let data = fileHandle.readDataToEndOfFile()
            
            let string = String(data: data, encoding: String.Encoding.utf8)
            handleNetWorkData(string!)
        } else {
            NSLog("Task failed.")
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
