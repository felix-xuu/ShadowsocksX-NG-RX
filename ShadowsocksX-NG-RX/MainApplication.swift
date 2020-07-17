//
//  MainApplication.swift
//  ShadowsocksX-NG-RX
//
//  Created by Felix Xu on 2020/7/17.
//  Copyright © 2020 felix.xu. All rights reserved.
//

import Foundation

@objc(MainApplication)
class MainApplication: NSApplication {
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
    override func sendEvent(_ event: NSEvent) {
        if (event.type == NSEvent.EventType.keyDown) {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self); return
                case "c":
                    NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self); return
                case "v":
                    NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self); return
                case "z":
                    NSApp.sendAction(Selector(("undo:")), to:nil, from:self); return
                case "a":
                    NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self); return
                default: break
                }
            }
            else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    NSApp.sendAction(Selector(("redo:")), to:nil, from:self)
                    return
                }
            }
        }
        super.sendEvent(event)
    }
}
