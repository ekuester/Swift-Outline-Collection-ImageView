//
//  OutlineViewController.swift
//  Swift Filesystem Treeview
//
//  Apple: Writing an Outline View Data Source
//  <https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/OutlineView/Articles/UsingOutlineDataSource.html>
//
//  Created by Erich Küster on February 5, 2017
//  Copyright © 2017 Erich Küster. All rights reserved.
//

import Cocoa

class OutlineViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    // MARK: - properties
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var pathController: NSPathControl!
    
    let lightCyanColor = CGColor(red: 0.897039 , green: 0.924751, blue: 0.974603, alpha: 1.0)
    let propertyKeys: [URLResourceKey] = [.localizedNameKey, .effectiveIconKey, .isDirectoryKey, .typeIdentifierKey]
    let sharedDocumentController = NSDocumentController.shared()
    
    var fileSystemBase: FileSystemItem!
    var recentItemsObserver: NSObjectProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = CGColor.clear
        outlineView.backgroundColor = NSColor(cgColor: lightCyanColor)!
        outlineView.gridColor = NSColor.gray
        // no table headers
        outlineView.headerView?.frame.size.height = 0
        outlineView.enclosingScrollView?.borderType = .noBorder
        outlineView.focusRingType = .default
        outlineView.action = #selector(onItemClicked)
        // notification if file from recent documents should be opened
        recentItemsObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "com.image.openview"), object: nil, queue: nil, using: openView)
        let userDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
        // start with directory "Pictures" as base folder
        let folderURL = userDirectoryURL.appendingPathComponent("Pictures", isDirectory: true)
        pathController.url = folderURL
        fileSystemBase = FileSystemItem(url: folderURL)
    }
    
    override func viewDidAppear() {
        // now window exists
        self.view.window?.makeFirstResponder(self)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
/*
    override func viewWillDisappear() {
        NotificationCenter.default.removeObserver(recentItemsObserver)
    }
 */
    func urlFromDialog(zipAllowed: Bool) {
        // generate File Open Dialog class
        let folderDialog: NSOpenPanel = NSOpenPanel()
        folderDialog.prompt = "Choose"
        folderDialog.title = NSLocalizedString("Select an URL for folder or ZIP archive", comment: "title of open panel")
        folderDialog.message = "Choose a directory or zip archive containing files:"
        folderDialog.directoryURL = self.pathController.url
        // allow only one directory or file at the same time
        folderDialog.allowsMultipleSelection = false
        folderDialog.canChooseDirectories = true
        if zipAllowed {
            folderDialog.allowedFileTypes = ["zip"]
            folderDialog.canChooseFiles = true
        }
        else {
            folderDialog.canChooseFiles = false
        }
        folderDialog.showsHiddenFiles = false
        folderDialog.beginSheetModal(for: view.window!, completionHandler: { response in
            // NSFileHandlingPanelOKButton is Int(1)
            guard response == NSFileHandlingPanelOKButton
                else {
                    // Cancel pressed, use old collection view if any
                    
                    return
            }
            DispatchQueue.main.async {
                if let url = folderDialog.url {
                    // note url of recent documents
                    self.sharedDocumentController.noteNewRecentDocumentURL(url)
                    self.pathController.url = url
                    self.fileSystemBase = FileSystemItem(url: url)
                    self.outlineView.reloadData()
                    // update collection view
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "com.collectionView.update"), object: self)
                }
            }
        })
    }
    
    @IBAction func pathControllerAction(_ sender: NSPathControl) {
        // On click on path controller update collection view
        urlFromDialog(zipAllowed: false)
    }
    
    @objc private func onItemClicked() {
    // <http://stackoverflow.com/questions/2253430/how-to-get-selected-item-of-nsoutlineview-without-using-nstreecontroller>
        let clickedRow = outlineView.clickedRow
        guard let item = outlineView.item(atRow: clickedRow) as? FileSystemItem
            else { return }
        if ((item != fileSystemBase) && item.hasChildren()) {
            // on click on directory entry of outline view update collection view
            fileSystemBase = item
            NotificationCenter.default.post(name: Notification.Name(rawValue: "com.collectionView.update"), object: self)
        }
    }
    
    // MARK: - notifications
    func openView(_ notification: Notification) {
        if let url = notification.object as? URL {
            // note url of recent documents again
            sharedDocumentController.noteNewRecentDocumentURL(url)
            self.pathController.url = url
            self.fileSystemBase = FileSystemItem(url: url)
            self.outlineView.reloadData()
            // update collection view
            NotificationCenter.default.post(name: Notification.Name(rawValue: "com.collectionView.update"), object: self)
        }
    }
    
    // MARK: actions for menu entries
    @IBAction func openDocument(_ sender: NSMenuItem) {
        // open new file(s)
        urlFromDialog(zipAllowed: false)
    }
    
    // MARK: - outline data source methods
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let fileSystemItem = item as? FileSystemItem {
            return fileSystemItem.children.count
        }
        return 1
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let fileSystemItem = item as? FileSystemItem {
            return fileSystemItem.hasChildren()
        }
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let fileSystemItem = item as? FileSystemItem {
            return fileSystemItem.children[index]
        }
        // collection view should update
        NotificationCenter.default.post(name: Notification.Name(rawValue: "com.collectionView.update"), object: self)
        return fileSystemBase
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let fileSystemItem = item as? FileSystemItem {
            switch tableColumn?.identifier {
            case "tree"?:
                return fileSystemItem.localizedName
            default:
                break
            }
        }
        return " -empty- "
    }
    
    // MARK: - outline view delegate methods
    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, item: Any) {
        guard let cell = cell as? NSTextFieldCell
            else { return }
        cell.textColor = NSColor.controlTextColor
        cell.backgroundColor = NSColor.controlBackgroundColor
        cell.font = NSFont.systemFont(ofSize: 12.0)
    }
    
}
