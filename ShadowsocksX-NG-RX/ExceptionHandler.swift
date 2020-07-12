//
//  ExceptionHandler.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2020/7/12.
//  Copyright © 2020 felix.xu. All rights reserved.
//

import Foundation

func signalExceptionHandler(signal:Int32) {
    saveExceptionFile(reason: nil, stackInfo: Thread.callStackSymbols)
    exit(signal)
}

func uncaughtExceptionHandler(exception: NSException) {
    saveExceptionFile(reason: exception.reason, stackInfo: exception.callStackSymbols)
}

func saveExceptionFile(reason: String?, stackInfo: [String]) {
    let content = reason ?? "Error" + "\n" + stackInfo.joined(separator: "\n")
    let path = NSHomeDirectory() + "/Library/Logs/ssr-crash.log"
    try? content.write(toFile: path, atomically: true, encoding: .utf8)
}
