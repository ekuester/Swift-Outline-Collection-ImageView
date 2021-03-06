//
//  ActionImageView.swift
//  Swift Filesystem Treeview
//  handles single an double clicks on the image view
//
//  Created by Erich Küster on January 06, 2017
//  Copyright © 2017 Erich Küster. All rights reserved.
//

import Cocoa

class ActionImageView: NSImageView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }

// MARK: Properties
    var contextMenu: NSMenu!
    var doubleAction: Selector?
    var menuAction: Selector?
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }

// MARK: Event Handling
    override func mouseDown(with event: NSEvent) {
        if let doubleAction = doubleAction, event.clickCount == 2 {
            NSApp.sendAction(doubleAction, to: target, from: self)
        }
        else {
            super.mouseDown(with: event)
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if let menuAction = menuAction, event.clickCount == 1 {
            NSApp.sendAction(menuAction, to: target, from: event)
        }
        else {
             super.rightMouseDown(with: event)
        }
    }
    
}
