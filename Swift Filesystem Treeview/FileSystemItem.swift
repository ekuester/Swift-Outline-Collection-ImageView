//
//  FileSystemItem.swift
//  Swift Filesystem Treeview
//
//  Created by Erich Küster on February 5, 2017
//  Copyright © 2017 Erich Küster. All rights reserved.
//

import Cocoa

class FileSystemItem: NSObject {
    
    let propertyKeys: [URLResourceKey] = [.localizedNameKey, .effectiveIconKey, .isDirectoryKey, .typeIdentifierKey]
    let resourceValueKeys: Set<URLResourceKey> = [.nameKey, .localizedNameKey, .effectiveIconKey, .isDirectoryKey, .typeIdentifierKey]
    
    var fileURL: URL
    var resourceValues: URLResourceValues?
    
    var name: String? {
        return resourceValues?.name
    }
    
    var localizedName: String? {
        return resourceValues?.localizedName
    }
    
    var icon: NSImage! {
        let resourceValues = try! fileURL.resourceValues(forKeys: [.effectiveIconKey])
        return resourceValues.effectiveIcon as? NSImage
    }
/*
    var dateOfCreation: Date! {
        return resourceValues.creationDate
    }
    
    var dateOfLastModification: Date! {
        return resourceValues.contentAccessDate
    }
 */
    var type: String? {
        return resourceValues?.typeIdentifier
    }
    
    var isDirectory: Bool? {
        return resourceValues?.isDirectory
    }
    
    var isEPS: Bool {
        return type == "com.adobe.encapsulated-postscript"
    }
    
    var isImage: Bool {
        return UTTypeConformsTo(type as! CFString, kUTTypeImage)
    }
    
    var isPDF: Bool {
        return type == "com.adobe.pdf"
    }
    
    var isZIP: Bool {
        return type == "public.zip-archive"
    }

    var parent: FileSystemItem? = nil
    var children: [FileSystemItem] {
        var childs: [FileSystemItem] = []
        let fileManager = FileManager.default
        // show no hidden Files (if you want this, remove .skipsHiddenFiles in next line)
        let options: FileManager.DirectoryEnumerationOptions =
            [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
        // var directoryURL = ObjCBool(false)
        let validURL = fileManager.fileExists(atPath: fileURL.relativePath)
        if (validURL && self.isDirectory!) {
            // contents of directory
            do {
                let childURLs = try
                    fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: propertyKeys, options: options)
                for childURL in childURLs {
                    let child = FileSystemItem(url: childURL)
                    childs.append(child)
                }
            }
            catch {
                print("Unexpected error occured: \(error).")
            }
        }
    return childs
    }

    func hasChildren() -> Bool {
        return (self.isDirectory! && (self.children.count > 0))
    }
    
    // thumbnail size 216 x 162 (= 4 : 3) for image, plus 216 x 22 for Label, gives 216 x 184 pixel
    fileprivate let thumbSize = CGSize(width: 216.0, height: 184.0)
    
    fileprivate func imageFrom(_ imageRep: NSImageRep, size: NSSize) -> NSImage? {
        return NSImage(size: size, flipped: false, drawingHandler:
            {   (rect: CGRect) in
                // set fill color
                NSColor.white.setFill()
                // fill image rect with white background
                NSRectFill(rect)
                imageRep.draw(in: rect)
                return true
            })
    }
    
    // thumbnail from image file at url
    var thumbnail: NSImage? {
        guard isEPS || isImage || isPDF
            else { return nil }
        var imageData: Data
        do {
            imageData = try Data(contentsOf: self.fileURL)
            if isPDF {
                if let pdfImageRep = NSPDFImageRep(data: imageData) {
                    // make image for first page
                    pdfImageRep.currentPage = 0
                    return imageFrom(pdfImageRep, size: pdfImageRep.bounds.size)
                }
            }
            if isEPS {
                // eps documents have per definitionem only one page
                if let epsImageRep = NSEPSImageRep(data: imageData) {
                    return imageFrom(epsImageRep, size: epsImageRep.boundingBox.size)
                }
            }
            if isImage {
                // if used in a collection view, no creation of thumbnail is fastest variant
                return NSImage(data: imageData)
            }
        }
        catch let error as NSError {
            print("error reading data from url: \(error.localizedDescription) in \(error.domain)")
        }
        return nil
    }
    
    init(url: Foundation.URL) {
        self.fileURL = url
        self.resourceValues = try! url.resourceValues(forKeys: resourceValueKeys)
    }
    
}
