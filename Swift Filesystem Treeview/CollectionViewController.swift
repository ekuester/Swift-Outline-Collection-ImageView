//
//  CollectionViewController.swift
//  Swift Filesystem Treeview
//
//  Created by Erich Küster on February 6, 2017
//  Copyright © 2017 Erich Küster. All rights reserved.
//

import Cocoa

// before the latest Swift 3, you could compare optional values
// Swift migrator solves that problem by providing a custom < operator
// which takes two optional operands and therefore "restores" the old behavior.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

class CollectionViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    @IBOutlet weak var enclosingScrollView: NSScrollView!
    
    var collectionView: NSCollectionView!
    var fileSystemBase: FileSystemItem!
    var imageDoubleClickedObserver: NSObjectProtocol!
    var imageFileItems: [FileSystemItem] = []
    var parentController: ContainerViewController!
    var updateCollectionObserver: NSObjectProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        parentController = self.parent as! ContainerViewController!
        collectionView = enclosingScrollView.documentView as! NSCollectionView
        imageDoubleClickedObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "com.image.doubleClicked"), object: nil, queue: nil, using: openImage)
        // notification from outline view controller to update collection view
        updateCollectionObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "com.collectionView.update"), object: nil, queue: nil, using: updateCollection)
    }
    
    override func viewDidAppear() {
        // now window exists
        if let imageFileItems = parentController.imageFileItems {
            self.imageFileItems = imageFileItems
            parentController.imageFileItems?.removeAll()
        }
        configureCollectionView()
        collectionView.layer?.backgroundColor = NSColor.darkGray.cgColor
        registerForDragAndDrop()
        collectionView.reloadData()
    }
    
    override func viewWillDisappear() {
        NotificationCenter.default.removeObserver(imageDoubleClickedObserver)
        NotificationCenter.default.removeObserver(updateCollectionObserver)
    }
    
    private func configureCollectionView() {
        collectionView.wantsLayer = true
        // item size 216 x 162 (= 4 : 3) for image  and 216 x 22 for Label, 216 x 184 pixel
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 216.0, height: 184.0)
        flowLayout.sectionInset = EdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        flowLayout.minimumInteritemSpacing = 10.0
        flowLayout.minimumLineSpacing = 10.0
        collectionView.collectionViewLayout = flowLayout
    }
    
    func registerForDragAndDrop() {
        // changed for Swift 3
        collectionView.register(forDraggedTypes: [NSURLPboardType])
        // from internal we always move
        collectionView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        // from external we always add
        collectionView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
    }
    
    // MARK: - NSCollectionViewDataSource
    // 1
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        // we have only one section
        return 1
    }
    // 2
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        // we are working only with an one-dimensional array of image files
        return imageFileItems.count
    }
    // 3
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "CollectionViewItem", for: indexPath)
        guard let collectionViewItem = item as? CollectionViewItem
            else { return item }
        // if you want to use more than one section, code has to be changed
        collectionViewItem.imageFile = imageFileItems[indexPath.item]
        if let selectedIndexPath = collectionView.selectionIndexPaths.first, selectedIndexPath == indexPath {
            collectionViewItem.setHighlight(true)
        } else {
            collectionViewItem.setHighlight(false)
        }
        return item
    }
    
    // MARK: - NSCollectionViewDelegate
    // 1
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        // if you are using more than one selected item, code has to be changed
        guard let indexPath = indexPaths.first
            else { return }
        guard let item = collectionView.item(at: indexPath) as? CollectionViewItem
            else { return }
        item.setHighlight(true)
    }
    // 2
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        // if you are using more than one selected item, code has to be changed
        guard let indexPath = indexPaths.first
            else { return }
        guard let item = collectionView.item(at: indexPath) as? CollectionViewItem
            else { return }
        item.setHighlight(false)
    }
    // 3
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexes: IndexSet, with event: NSEvent) -> Bool {
        return true
    }
    
    // MARK: - notifications
    func openImage(_ notification: Notification) {
        // invoked when an item of the collectionview is double clicked
        if let imageFile = notification.object as? FileSystemItem {
            guard let imageIndex = self.imageFileItems.index(of: imageFile)
                else { return }
            parentController.imageFileItems = self.imageFileItems
            parentController.imageFileIndex = imageIndex
            self.imageFileItems.removeAll()
            self.performSegue(withIdentifier: "ShowImageSegue", sender: self)
        }
    }
    
    func updateCollection(_ notification: Notification) {
        if let controller = notification.object as? OutlineViewController {
            fileSystemBase = controller.fileSystemBase
            if fileSystemBase.hasChildren() {
                imageFileItems.removeAll()
                for child in fileSystemBase.children {
                    if child.thumbnail != nil {
                        imageFileItems.append(child)
                    }
                }
                collectionView.reloadData()
            }
        }
    }
}
