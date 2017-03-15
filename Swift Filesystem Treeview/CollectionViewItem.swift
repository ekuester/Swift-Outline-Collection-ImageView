//
//  CollectionViewItem.swift
//  Swift Filesystem Treeview
//
//  Created by Erich Küster on December 16, 2016
//  Copyright © 2016 Erich Küster. All rights reserved.
//

import Cocoa

class CollectionViewItem: NSCollectionViewItem {
    
    // light cyan
    let lightCyanColor = CGColor(red: 0.897039 , green: 0.924751, blue: 0.974603, alpha: 1.0)
    
    @IBOutlet weak var contextMenu: NSMenu!
    
    var imageFile: FileSystemItem? {
        didSet {
            guard isViewLoaded
                else { return }
            imageView?.image = imageFile?.thumbnail
            textField?.stringValue = (imageFile?.name)!
        }
    }
    
    var imageViewController: NSViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.borderWidth = 0.0
        // light blue
        view.layer?.borderColor = lightCyanColor
        // If the set image view is a ActionImageView, set the double click handler
        if let imageView = imageView as? ActionImageView {
            imageView.doubleAction = #selector(handleDoubleClickInImageView)
            imageView.menuAction = #selector(handleRightClickInImageView)
            imageView.target = self
        }
    }
    
    func setHighlight(_ selected: Bool) {
        if selected {
            view.layer?.borderWidth = 2.0
            // show thumbnail of item in separate image view
            if let imageController = imageViewController {
                let imageSubview = imageController.view.subviews.first as! NSImageView
                imageSubview.image = imageFile?.thumbnail
            }
        }
        else {
            view.layer?.borderWidth = 0.0
        }
    }
    
    // MARK: Actions
    func handleDoubleClickInImageView(_ sender: AnyObject?) {
        // On double click, show the image in a new view
        NotificationCenter.default.post(name: Notification.Name(rawValue: "com.image.doubleClicked"), object: self.imageFile)
    }
    
    func handleRightClickInImageView(_ sender: AnyObject?) {
        // On right mouse click, show a menue
        if let event = sender as? NSEvent {
            if let menuItem = contextMenu.item(at: 0) {
                menuItem.representedObject = self
            }
            NSMenu.popUpContextMenu(contextMenu, with: event, for: self.imageView!)
        }
    }
    
}
