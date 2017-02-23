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
    
    var imageFile: FileSystemItem? {
        didSet {
            guard isViewLoaded
                else { return }
            imageView?.image = imageFile?.thumbnail
            textField?.stringValue = (imageFile?.name)!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.borderWidth = 0.0
        // light blue
        view.layer?.borderColor = lightCyanColor
        // If the set image view is a DoubleActionImageView, set the double click handler
        if let imageView = imageView as? DoubleActionImageView {
            imageView.doubleAction = #selector(CollectionViewItem.handleDoubleClickInImageView(_:))
            imageView.target = self
        }
    }
    
    func setHighlight(_ selected: Bool) {
        view.layer?.borderWidth = selected ? 2.0 : 0.0
    }
    
    // MARK: IBActions
    @IBAction func handleDoubleClickInImageView(_ sender: AnyObject?) {
        // On double click, show the image in a new view
        NotificationCenter.default.post(name: Notification.Name(rawValue: "com.image.doubleClicked"), object: self.imageFile)
    }
    
}
