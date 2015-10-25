//
//  MealTableViewController.swift
//  FoodTracker
//
//  Created by Jason Smith on 9/5/2558 BE.
//
//

import UIKit

class MealTableViewController: UITableViewController, CDTReplicatorDelegate {
    
    // MARK: Properties
    
    var meals = [Meal]()
    var datastore: CDTDatastore?
    var pushReplicator: CDTReplicator?
    var pullReplicator: CDTReplicator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem()
          
        initDatastore()
        storeSampleMeals()
        loadMealsFromDataStore()
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
            deleteMeal(meals[indexPath.row])
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
    
    // MARK: Datastore
    
    func initDatastore() {
        var manager: CDTDatastoreManager
        
        do {
            let fileManager = NSFileManager.defaultManager()
            
            let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory,
                inDomains: .UserDomainMask).last!
            
            let storeURL = documentsDir.URLByAppendingPathComponent("cloudant-sync-datastore")
            let path = storeURL.path
            
            manager = try CDTDatastoreManager(directory: path)
            datastore = try manager.datastoreNamed("my_datastore")
        } catch {
            print("Error initializing datastore: \(error)")
            return
        }
        
        let username = "dsomentypianshavesientan"
        let url = NSURL(string: "https://\(username):42ec1fdd001520ec09f17947f14d079927c0b5ea@nodejs.cloudant.com/food_tracker")
        
        // Create a "push" replicator, to copy local changes to the remote database.
        let push = CDTPushReplication(source: datastore, target: url)
        let replicatorFactory = CDTReplicatorFactory(datastoreManager: manager)
        
        do {
            pushReplicator = try replicatorFactory.oneWay(push)
            try pushReplicator!.start()
        } catch {
            print("Error initializing push replication: \(error)")
            return
        }
        
        while pushReplicator!.isActive() {
            print(" -> ", CDTReplicator.stringForReplicatorState(pushReplicator!.state))
            NSThread.sleepForTimeInterval(1.0)
        }
    }
    
    func storeSampleMeals() {
        let photo1 = UIImage(named: "meal1")!
        let meal1  = Meal(name: "Caprese Salad", photo: photo1, rating: 4, docId: "meal1")!
        saveMeal(meal1, create:true)
        
        let photo2 = UIImage(named: "meal2")!
        let meal2 = Meal(name: "Chicken and Potatoes", photo: photo2, rating: 5, docId:"meal2")!
        saveMeal(meal2, create:true)
        
        let photo3 = UIImage(named: "meal3")
        let meal3 = Meal(name: "Pasta with Meatballs", photo: photo3, rating: 3, docId:"meal3")!
        saveMeal(meal3, create:true)
    }
    
    func saveMeal(meal:Meal) {
        saveMeal(meal, create:false)
    }
    
    func saveMeal(meal:Meal, create:Bool) {
        var rev = CDTMutableDocumentRevision()
        let docId = meal.docId
        
        // First, fetch the latest revision from the DB.
        if docId != nil && !create {
            do {
                print("Update meal: \(docId)")
                rev = try datastore!.getDocumentWithId(docId).mutableCopy()
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
        
        rev.docId = docId
        let body = rev.body()
        body["name"] = meal.name
        body["rating"] = meal.rating
        
        if let data = UIImagePNGRepresentation(meal.photo!) {
            let attachment = CDTUnsavedDataAttachment(data: data, name: "photo.jpg", type: "image/jpg")
            rev.attachments()[attachment.name] = attachment
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
    
    func deleteMeal(meal: Meal) {
        print("delete meal: \(meal.name)")
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
                saveMeal(meal)
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
            } else {
                // Add the new meal.
                let newIndexPath = NSIndexPath(forRow: meals.count, inSection: 0)
                meals.append(meal)
                saveMeal(meal)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
            }
        }
    }
}
