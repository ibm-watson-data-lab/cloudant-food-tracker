//
//  Meal.swift
//  FoodTracker
//
//  Created by Jason Smith on 9/5/2558 BE.
//
//

import UIKit

class Meal: NSObject {
    // MARK: Properties
    
    var name: String
    var photo: UIImage?
    var rating: Int
    var dbRevision: CDTMutableDocumentRevision?
    
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
    
    init?(name: String, photo: UIImage?, rating: Int, rev: CDTMutableDocumentRevision?) {
        // Initialize the properties.
        self.name = name
        self.photo = photo
        self.rating = rating
        self.dbRevision = rev
        
        super.init()
        
        if name.isEmpty || rating < 0 {
            return nil
        }
    }
    
    required convenience init?(name: String, photo: UIImage?, rating: Int) {
        self.init(name:name, photo:photo, rating:rating, rev:nil)
    }
    
    required convenience init?(aDoc doc:CDTDocumentRevision) {
        if let body = doc.body() as? [String: AnyObject] {
            let name = body["name"] as! String
            let rating = body["rating"] as! Int
            
            var photo : UIImage? = nil
            if let photoAttachment = doc.attachments()["photo.jpg"] {
                print("Attachment! \(photoAttachment)")
                photo = UIImage(data: photoAttachment.dataFromAttachmentContent())
            }

            self.init(name:name, photo:photo, rating:rating, rev:doc.mutableCopy())
        } else {
            print("Error initializing meal from document: \(doc)")
            return nil
        }
    }
}