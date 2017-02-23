//
//  CrossfadeStoryboardSegue.swift
//  Swift Filesystem Treeview
//
//  Created by Erich Küster on December 16, 2016
//  Copyright © 2016 Erich Küster. All rights reserved.
//

import Cocoa

class CrossfadeStoryboardSegue: NSStoryboardSegue {

    // make references to the source controller and destination controller
    override init(identifier: String?, source sourceController: Any, destination destinationController: Any) {
        var myIdentifier: String
        if identifier == nil {
            myIdentifier = ""
        } else {
            myIdentifier = identifier!
        }
        super.init(identifier: myIdentifier, source: sourceController, destination: destinationController)
    }

    override func perform() {
        // build from-to and parent-child view controller relationships
        let sourceViewController  = self.sourceController as! NSViewController
        let destinationViewController = self.destinationController as! NSViewController
        let parentController = sourceViewController.parent! as! ContainerViewController
        let outlineViewController = parentController.childViewControllers.first as! OutlineViewController
        // add destinationViewController as child
        parentController.insertChildViewController(destinationViewController, at: 2)
        // prepare for animation
        sourceViewController.view.wantsLayer = true
        destinationViewController.view.wantsLayer = true

        // perform transition animating with NSViewControllerTransitionOptions
        let containerWindow = parentController.view.window!
        if self.sourceController is CollectionViewController {
            if !parentController.inFullScreen {
                // remove outline view
                outlineViewController.view.removeFromSuperview()
            }
            // show single image
            parentController.transition(from: sourceViewController, to: destinationViewController, options: [NSViewControllerTransitionOptions.crossfade], completionHandler: nil)

            // lose the not longer required sourceViewController, it's no longer visible
            parentController.removeChildViewController(at: 1)

            let imageFileIndex = parentController.imageFileIndex
            parentController.imageViewfromImageFileIndex(imageFileIndex)
            // add "Navigate" submenu
            let subItem = NSApp.mainMenu!.insertItem(withTitle: "Navigate", action: nil, keyEquivalent: "", at: 5)
            NSApp.mainMenu?.setSubmenu(parentController.navigate, for: subItem)
        }
        else {
            // show collection view again
            let targetRect = parentController.inFullScreen ? parentController.mainFrame! : parentController.rightContent
            parentController.transition(from: sourceViewController, to: destinationViewController, options: [NSViewControllerTransitionOptions.crossfade], completionHandler: nil)
            containerWindow.setTitleWithRepresentedFilename("Choose a Directory on the Left")
            //resize view controller
            NSAnimationContext.current().duration = 1.0
            sourceViewController.view.animator().frame = targetRect
            // set frame for container view window
            containerWindow.setFrame(parentController.mainFrame, display: true, animate: true)
            // lose the not longer required sourceViewController, it's no longer visible
            parentController.removeChildViewController(at: 1)
            if !parentController.inFullScreen {
                parentController.view.addSubview(outlineViewController.view)
            }
            // remove submenu "Navigate"
            NSApp.mainMenu?.removeItem(at: 5)
        }
    }
}
