//
//  MealTableViewController.swift
//  FoodTracker
//
//  Created by Jason Smith on 9/5/2558 BE.
//
//

import UIKit

class MealTableViewController: UITableViewController {
    
    // MARK: Properties
    
    var meals = [Meal]()
    var datastore: CDTDatastore?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem()
          
        initDatastore()
        storeSampleMeals()
        let savedMeals = loadMealsFromDataStore()
        meals += savedMeals
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
        
        // Fetch the appropriate meal for the data source layout.
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
            saveMeals()
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
    
    // MARK: Datastore
    
    func initDatastore() {
        do {
            let fileManager = NSFileManager.defaultManager()
            
            let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory,
                inDomains: .UserDomainMask).last!
            
            let storeURL = documentsDir.URLByAppendingPathComponent("cloudant-sync-datastore")
            let path = storeURL.path
            
            let manager = try CDTDatastoreManager(directory: path)
            datastore = try manager.datastoreNamed("my_datastore")
        } catch {
            print("Error initializing datastore: \(error)")
        }
    }
    
    func storeSampleMeals() {
        let photo1 = UIImage(named: "meal1")!
        let meal1  = Meal(name: "Caprese Salad", photo: photo1, rating: 4)!
        storeMeal(meal1)
        
        let photo2 = UIImage(named: "meal2")!
        let meal2 = Meal(name: "Chicken and Potatoes", photo: photo2, rating: 5)!
        storeMeal(meal2)
        
        let photo3 = UIImage(named: "meal3")
        let meal3 = Meal(name: "Pasta with Meatballs", photo: photo3, rating: 3)!
        storeMeal(meal3)
    }
    
    func storeMeal(meal:Meal) {
        let id = meal.name
        
        do {
            print("Store meal: \(meal)")
            let body = meal.docBody() //as NSMutableDictionary
            print("Meal doc: \(body)")
            let rev = CDTMutableDocumentRevision()
            rev.docId = id
            rev.setBody(body)
            let revision = try datastore!.createDocumentFromRevision(rev)
            print("Store ok \(id) = \(revision.revId!)")
        } catch let error as NSError {
            if let reason = error.userInfo["NSLocalizedFailureReason"] {
                if (reason as! String == "conflict") {
                    print("Just a conflict, no big deal: \(id)")
                } else {
                    print("Error storing meal \(id): \(reason)")
                }
            } else {
                print("Unknown error storing meal \(id): \(error)")
            }
        }
    }

    func loadMealsFromDataStore() -> [Meal] {
        let docs = datastore!.getAllDocuments()
        print("Found \(docs.count) meal documents in datastore: \(docs)")

        // Add an attachment - binary data like a JPEG
        //            let att1 = CDTUnsavedFileAttachment(path: "/path/to/image/jpg",
        //                name: "cute_cat.jpg",
        //                type: "image/jpeg")
        //            rev.attachments[att1.name] = att1
        
        // Save the document to the database
        //            let revision = try datastore!.createDocumentFromRevision(rev)
        
        // Read a document
        //            let docId = revision.docId
        //            let retrieved = try datastore!.getDocumentWithId(docId)
        //            print("retrieved = \(retrieved)")
    
        let mealsFromDB : [Meal] = []
        return mealsFromDB
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            let mealDetailViewController = segue.destinationViewController as! MealViewController
            if let selectedMealCell = sender as? MealTableViewCell {
                let indexPath = tableView.indexPathForCell(selectedMealCell)!
                let selectedMeal = meals[indexPath.row]
                mealDetailViewController.meal = selectedMeal
            }
        }
        else if segue.identifier == "AddItem" {
            print("Add new meal")
        }
    }
    
    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.sourceViewController as? MealViewController, meal = sourceViewController.meal {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing meal.
                meals[selectedIndexPath.row] = meal
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
            } else {
                // Add the new meal.
                let newIndexPath = NSIndexPath(forRow: meals.count, inSection: 0)
                meals.append(meal)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
            }
            
            saveMeals()
        }
    }

    // MARK: NSCoding
    
    func saveMeals() {
        let path = Meal.ArchiveURL.path!
        
        print("Save meals: \(path)")
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(meals, toFile: path)
        print("  Save result: \(isSuccessfulSave)")
    }
}
