//
//  PingClient.swift
//  ShadowsocksX-R
//
//  Created by 称一称 on 16/9/5.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation

class PingServers:NSObject {
    static let instance = PingServers()
    
    func runCommand(cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, error, status)
    }
    
    func getlatencyFromString(result:String) -> Double?{
        var res = result
        if !result.contains("round-trip min/avg/max/stddev =") {
            return nil
        }
        res.removeSubrange(res.range(of: "round-trip min/avg/max/stddev = ")!)
        res = String(res.dropLast(3))
        res = res.components(separatedBy: "/")[1]
        let latency = Double(res)
        return latency
    }
    
    func pingSingleHost(host:String,completionHandler:@escaping (Double?) -> Void){
        DispatchQueue.global(qos: .userInteractive).async {
            if let outputString = self.runCommand(cmd: "/sbin/ping", args: "-c", "1", "-t", "1.5", host).output.last{
                completionHandler(self.getlatencyFromString(result: outputString))
            }
        }
    }
    
    func ping(_ i: Int=0) {
        var result: [(Int, Int, Double)] = []
        
        for k in 0..<ServerGroupManager.serverGroups.count {
            let profiles = ServerGroupManager.serverGroups[k].serverProfiles
            for j in 0..<profiles.count {
                let host = profiles[j].serverHost
                pingSingleHost(host: host, completionHandler: {
                    if let latency = $0 {
                        profiles[j].latency = String(latency)
                    } else {
                        profiles[j].latency = "timeout"
                    }
                    if let active = ServerProfileManager.activeProfile {
                        if active.uuid == profiles[j].uuid {
                            ServerProfileManager.setActiveProfile(profiles[j])
                        }
                    }
                })
            }
        }
        
        delay(3) {
            DispatchQueue.main.async {
                for k in 0..<ServerGroupManager.serverGroups.count {
                    let profiles = ServerGroupManager.serverGroups[k].serverProfiles
                    for j in 0..<profiles.count {
                        if let late = profiles[j].latency {
                            if let latency = Double(late){
                                result.append((k, j, latency))
                            }
                        }
                    }
                }
                (NSApplication.shared.delegate as! AppDelegate).updateServersMenu()
                (NSApplication.shared.delegate as! AppDelegate).updateServerMenuItemState()
                
                let min = result.min(by: {$0.2 < $1.2})
                
                let groupName = ServerGroupManager.serverGroups[min!.0].groupName
                notificationDeliver(title: "Done the ping, the fastest as follow", subTitle: "", text: "\(groupName)"
                    + " - \(ServerGroupManager.serverGroups[min!.0].serverProfiles[min!.1].remark)"
                    + " - \(ServerGroupManager.serverGroups[min!.0].serverProfiles[min!.1].latency!)ms")
            }
        }
    }
}

typealias Task = (_ cancel : Bool) -> Void

@discardableResult func delay(_ time: TimeInterval, task: @escaping ()->()) ->  Task? {
    
    func dispatch_later(block: @escaping ()->()) {
        let t = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: t, execute: block)
    }
    var closure: (()->Void)? = task
    var result: Task?
    
    let delayedClosure: Task = {
        cancel in
        if let internalClosure = closure {
            if (cancel == false) {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayedClosure
    
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    return result
}

