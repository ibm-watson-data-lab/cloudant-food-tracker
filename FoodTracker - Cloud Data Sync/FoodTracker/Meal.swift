//
//  Meal.swift
//  FoodTracker
//
//  Created by Jane Appleseed on 5/26/15.
//  Copyright © 2015 Apple Inc. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information.
//

import UIKit

class Meal: NSObject {
    // MARK: Properties
    
    var name: String
    var photo: UIImage?
    var rating: Int
    var docId: String?
    var createdAt: NSDate
    
    // MARK: Archiving Paths
    
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("meals")
    
    // MARK: Types
    
    struct PropertyKey {
        static let nameKey = "name"
        static let photoKey = "photo"
        static let ratingKey = "rating"
    }

    // MARK: Initialization
    
    init?(name: String, photo: UIImage?, rating: Int, docId: String?) {
        // Initialize stored properties.
        self.name = name
        self.photo = photo
        self.rating = rating
        self.docId = docId
        self.createdAt = NSDate()
        
        super.init()
        
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty || rating < 0 {
            return nil
        }
    }

    required convenience init?(aDoc doc:CDTDocumentRevision) {
        if let body = doc.body {
            let name = body["name"] as! String
            let rating = body["rating"] as! Int
            
            var photo : UIImage? = nil
            if let photoAttachment = doc.attachments["photo.jpg"] {
                photo = UIImage(data: photoAttachment.dataFromAttachmentContent())
            }
            
            self.init(name:name, photo:photo, rating:rating, docId:doc.docId)
        } else {
            print("Error initializing meal from document: \(doc)")
            return nil
        }
    }
}