//
//  MealTableViewController.swift
//  FoodTracker
//
//  Created by Jane Appleseed on 5/27/15.
//  Copyright © 2015 Apple Inc. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information.
//

import UIKit

class MealTableViewController: UITableViewController {
    // MARK: Properties
    
    var meals = [Meal]()
    var datastoreManager: CDTDatastoreManager?
    var datastore: CDTDatastore?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem()
        
        // Initialize the Cloudant Sync local datastore.
        let fileManager = NSFileManager.defaultManager()
        
        let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory,
            inDomains: .UserDomainMask).last!
        
        let storeURL = documentsDir.URLByAppendingPathComponent("foodtracker-data")
        let path = storeURL.path
        
        do {
            datastoreManager = try CDTDatastoreManager(directory: path)
            datastore = try datastoreManager!.datastoreNamed("meals")
        } catch {
            fatalError("Failed to initialize datastore: \(error)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meals.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "MealTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! MealTableViewCell
        
        // Fetches the appropriate meal for the data source layout.
        let meal = meals[indexPath.row]
        
        cell.nameLabel.text = meal.name
        cell.photoImageView.image = meal.photo
        cell.ratingControl.rating = meal.rating
        
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            meals.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }


    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            let mealDetailViewController = segue.destinationViewController as! MealViewController
            
            // Get the cell that generated this segue.
            if let selectedMealCell = sender as? MealTableViewCell {
                let indexPath = tableView.indexPathForCell(selectedMealCell)!
                let selectedMeal = meals[indexPath.row]
                mealDetailViewController.meal = selectedMeal
            }
        }
        else if segue.identifier == "AddItem" {
            print("Adding new meal.")
        }
    }
    

    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.sourceViewController as? MealViewController, meal = sourceViewController.meal {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing meal.
                meals[selectedIndexPath.row] = meal
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
            } else {
                // Add a new meal.
                let newIndexPath = NSIndexPath(forRow: meals.count, inSection: 0)
                meals.append(meal)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
            }
        }
    }
    
    // MARK: Datastore
    
    func saveMeal(meal:Meal) {
        saveMeal(meal, create:false)
    }
    
    func saveMeal(meal:Meal, create:Bool) {
        let docId = meal.docId
        var rev = CDTDocumentRevision(docId: docId)
        
        // First, fetch the latest revision from the DB.
        if docId != nil && !create {
            do {
                print("Update meal: \(docId)")
                rev = try datastore!.getDocumentWithId(docId)
                print("retrieved", rev)
            } catch let error as NSError {
                if let reason = error.userInfo["NSLocalizedFailureReason"] as? String {
                    print("Error loading meal \(docId): \(reason)")
                } else {
                    print("Error loading meal \(docId): \(error)")
                }
                return
            }
        }
        
        rev.body["name"] = meal.name
        rev.body["rating"] = meal.rating
        
        if let data = UIImagePNGRepresentation(meal.photo!) {
            let attachment = CDTUnsavedDataAttachment(data: data, name: "photo.jpg", type: "image/jpg")
            rev.attachments[attachment.name] = attachment
            print("Meal \(docId) attachment: \(attachment.size) bytes")
        }
        
        do {
            var revision: CDTDocumentRevision
            if create {
                revision = try datastore!.createDocumentFromRevision(rev)
                print("Created \(revision.docId)")
            } else {
                revision = try datastore!.updateDocumentFromRevision(rev)
                print("Updated \(revision.docId)")
            }
        } catch let error as NSError {
            if let reason = error.userInfo["NSLocalizedFailureReason"] as? String {
                if (reason == "conflict" && create) {
                    print("Update conflict is ok: \(docId)")
                } else {
                    print("Error storing meal \(docId): \(reason)")
                }
            } else {
                print("Unknown error storing meal \(docId): \(error)")
            }
        }
    }
}
