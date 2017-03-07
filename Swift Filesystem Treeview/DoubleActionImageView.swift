//
//  DoubleActionImageView.swift
//  Swift Filesystem Treeview
//
//  Created by Erich Küster on January 06, 2017
//  Copyright © 2017 Erich Küster. All rights reserved.
//

import Cocoa

class DoubleActionImageView: NSImageView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }

// MARK: Properties
    var doubleAction: Selector?
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }

// MARK: Event Handling
    override func mouseDown(with event: NSEvent) {
        if let doubleAction = doubleAction , event.clickCount == 2 {
            NSApp.sendAction(doubleAction, to: target, from: self)
        }
        else {
            super.mouseDown(with: event)
        }
    }

}
