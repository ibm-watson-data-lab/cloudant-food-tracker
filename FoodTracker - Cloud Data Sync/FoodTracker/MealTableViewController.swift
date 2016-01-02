//
//  MealTableViewController.swift
//  FoodTracker
//
//  Created by Jane Appleseed on 5/27/15.
//  Copyright © 2015 Apple Inc. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information.
//

import UIKit

class MealTableViewController: UITableViewController, CDTReplicatorDelegate {
    // MARK: Properties
    
    var meals = [Meal]()
    
    var datastoreManager: CDTDatastoreManager?
    var datastore: CDTDatastore?
    var pullReplicator: CDTReplicator?
    var pushReplicator: CDTReplicator?
//    var pushReplicator: CDTReplicator?
//    var pullReplicator: CDTReplicator?
//    var pushReplication: CDTPushReplication?
//    var pullReplication: CDTPullReplication?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem()
        
        // Initialize the Cloudant Sync local datastore.
        initDatastore()
        cloudPush() // XXX
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
            let meal = meals[indexPath.row]
            deleteMeal(meal)
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
                updateMeal(meal)
            } else {
                // Add a new meal.
                let newIndexPath = NSIndexPath(forRow: meals.count, inSection: 0)
                meals.append(meal)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
                createMeal(meal)
            }
        }
    }
    
    // MARK: Datastore

    func initDatastore() {
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
        
        // The datastore is now ready. Next, initialize the sample meals.
        storeSampleMeals()
        
        // Everything is ready. Load all meals from the datastore.
        loadMealsFromDataStore()
    }
    
    func populateRevision(meal: Meal, revision: CDTDocumentRevision?) {
        // Populate a document revision from a Meal.
        let rev: CDTDocumentRevision = revision ?? CDTDocumentRevision(docId: meal.docId)
        rev.body["name"] = meal.name
        rev.body["rating"] = meal.rating
        
        if let data = UIImagePNGRepresentation(meal.photo!) {
            let attachment = CDTUnsavedDataAttachment(data: data, name: "photo.jpg", type: "image/jpg")
            rev.attachments[attachment.name] = attachment
        }
    }

    func deleteMeal(meal: Meal) {
        updateMeal(meal, isDelete: true)
    }
    
    func updateMeal(meal: Meal) {
        updateMeal(meal, isDelete: false)
    }
    
    func updateMeal(meal: Meal, isDelete: Bool) {
        guard let docId = meal.docId else {
            print("Cannot update a meal with no document ID")
            return
        }

        let label = isDelete ? "Delete" : "Update"
        print("\(label) \(docId)")
        
        // First, fetch the current document revision from the DB.
        var rev: CDTDocumentRevision
        do {
            rev = try datastore!.getDocumentWithId(docId)
            populateRevision(meal, revision: rev)
        } catch {
            print("Error loading meal \(docId): \(error)")
            return
        }

        do {
            var result: CDTDocumentRevision
            if (isDelete) {
                result = try datastore!.deleteDocumentFromRevision(rev)
            } else {
                result = try datastore!.updateDocumentFromRevision(rev)
            }
            print("\(label) \(docId): \(result.revId)")
        } catch {
            print("Error updating \(docId): \(error)")
            return
        }
    }
    
    func createMeal(meal: Meal) {
        // User-created meals will have docId == nil. Sample meals have a string docId.
        // For sample meals, look up the existing doc. There will be three possibilities:
        //   1. No exceptionThe sample has already been created (and is still present)
        //   2. The sample has already been created, but was subsequently deleted.
        //   3. The sample has never been created.
        if let docId = meal.docId {
            do {
                try datastore!.getDocumentWithId(docId)
                print("Skip \(docId) creation: already exists")
                return
            } catch let error as NSError {
                if (error.userInfo["NSLocalizedFailureReason"] as? String != "not_found") {
                    print("Skip \(docId) creation: already deleted by user")
                    return
                }
                
                print("Create sample meal: \(docId)")
            }
        }
        
        let rev = CDTDocumentRevision(docId: meal.docId)
        populateRevision(meal, revision: rev)
        
        do {
            let result = try datastore!.createDocumentFromRevision(rev)
            print("Created \(result.docId) \(result.revId)")
        } catch {
            print("Error creating meal: \(error)")
        }
    }
    
    func storeSampleMeals() {
        let photo1 = UIImage(named: "meal1")!
        let photo2 = UIImage(named: "meal2")!
        let photo3 = UIImage(named: "meal3")
        
        let meal1 = Meal(name: "Caprese Salad", photo: photo1, rating: 4, docId: "sample-1")!
        let meal2 = Meal(name: "Chicken and Potatoes", photo: photo2, rating: 5, docId:"sample-2")!
        let meal3 = Meal(name: "Pasta with Meatballs", photo: photo3, rating: 3, docId:"sample-3")!
        
        createMeal(meal1)
        createMeal(meal2)
        createMeal(meal3)
    }
    
    func loadMealsFromDataStore() {
        let docs = datastore!.getAllDocuments() as! [CDTDocumentRevision]
        print("Found \(docs.count) meal documents in datastore: \(docs)")
        
        for doc in docs {
            if let meal = Meal(aDoc: doc) {
                meals.append(meal)
            }
        }
    }
    
    // MARK: Cloudant Sync
    
    func cloudURL() -> NSURL {
        // Change these to reflect your own Cloudant account and credentials.
        let account = "foodtracker"
        let dbName = "meals"
        let apiKey = "andifecternarlitirsetion"
        let apiPassword = "356dcd854fe9930cbca96e77dccbfd2af3f5f83f"
        
        let url = "https://\(apiKey):\(apiPassword)@\(account).cloudant.com/\(dbName)"
        return NSURL(string: url)!
    }
    
    func cloudPush() {
        // Push local data to the central cloud.
        
        // Describe the replication "direction" (pull from remote, or push from local).
        let job = CDTPullReplication(source: cloudURL(), target: datastore!)
        let factory = CDTReplicatorFactory(datastoreManager: datastoreManager)
        
        do {
            pullReplicator = try factory.oneWay(job)
            let p = pullReplicator!
            p.delegate = self
            print("Start")
            try p.start()
            print("Started")
        } catch {
            print("Error initializing sync: \(error)")
        }
    }
    
    func replicatorDidChangeState(replicator: CDTReplicator!) {
        print("Replication state \(replicator)")
    }
    
    func replicatorDidChangeProgress(replicator: CDTReplicator!) {
        print("Replication progress \(replicator)")
    }
    
    func replicatorDidComplete(replicator: CDTReplicator!) {
        print("Replication complete \(replicator)")
    }
    
    func replicatorDidError(replicator: CDTReplicator!, info: NSError!) {
        print("Replicator error \(replicator) \(info)")
    }
}
