//
//  MealTableViewController.swift
//  FoodTracker
//
//  Created by Jane Appleseed on 5/27/15.
//  Copyright © 2015 Apple Inc. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information.
//

import UIKit

class MealTableViewController: UITableViewController, CDTReplicatorDelegate, CDTHTTPInterceptor {
    // MARK: Properties
    
    var meals = [Meal]()
    
    var datastoreManager: CDTDatastoreManager?
    var datastore: CDTDatastore?
    var replications = [SyncDirection: CDTReplicator]()
    
    // Define two sync directions, push and pull.
    enum SyncDirection {
        case Push
        case Pull
    }
    
    // MARK: IBM Cloudant Settings
    
    // Change these for your own application.
    let userAgent = "FoodTracker"
    let cloudantAccount = "foodtracker"
    let cloudantDBName = "food_tracker"
    let cloudantApiKey = "facringediftedgentlerrad"
    let cloudantApiPassword = "ee4c30dbd2f7457ccf6804f9536ad1a79f0ea9ad"

//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        print("Automatic sync upon load up")
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem()
        
        // Initialize the Cloudant Sync local datastore.
        initDatastore()
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
            
            // Immediately sync to Cloudant.
            sync(.Push)
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
                
                // Mark the meal in-flight. When sync completes, the indicator will stop.
                let cell = tableView.cellForRowAtIndexPath(selectedIndexPath) as! MealTableViewCell
                cell.syncIndicator.startAnimating()
            } else {
                // Add a new meal.
                let newIndexPath = NSIndexPath(forRow: meals.count, inSection: 0)
                meals.append(meal)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
                createMeal(meal)
                
                // Mark the meal in-flight. When sync completes, the indicator will stop.
                let cell = tableView.cellForRowAtIndexPath(newIndexPath) as! MealTableViewCell
                cell.syncIndicator.startAnimating()
            }
            
            sync(.Push)
        }
    }
    
    // MARK: Datastore

    func initDatastore() {
        let fileManager = NSFileManager.defaultManager()
        
        let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory,
            inDomains: .UserDomainMask).last!
        
        let storeURL = documentsDir.URLByAppendingPathComponent("foodtracker-meals")
        let path = storeURL.path
        
        do {
            datastoreManager = try CDTDatastoreManager(directory: path)
            datastore = try datastoreManager!.datastoreNamed("meals")
        } catch {
            fatalError("Failed to initialize datastore: \(error)")
        }
        
        datastore?.ensureIndexed(["created_at"], withName: "timestamps")
        
        // The datastore is now ready. Next, initialize the sample meals.
        storeSampleMeals()
        
        // Everything is ready. Load all meals from the datastore.
        loadMealsFromDataStore()
    }
    
    func populateRevision(meal: Meal, revision: CDTDocumentRevision?) {
        // Populate a document revision from a Meal.
        let rev: CDTDocumentRevision = revision
            ?? CDTDocumentRevision(docId: meal.docId)
        rev.body["name"] = meal.name
        rev.body["rating"] = meal.rating
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let createdAtISO = dateFormatter.stringFromDate(meal.createdAt)
        rev.body["created_at"] = createdAtISO
        
        if let data = UIImagePNGRepresentation(meal.photo!) {
            let attachment = CDTUnsavedDataAttachment(data: data,
                name: "photo.jpg", type: "image/jpg")
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
    
    // Create a meal. Return true if the meal was created, or false if
    // creation was unnecessary.
    func createMeal(meal: Meal) -> Bool {
        // User-created meals will have docId == nil. Sample meals have a
        // string docId. For sample meals, look up the existing doc, with
        // three possible outcomes:
        //   1. No exception; the doc is already present. Do nothing.
        //   2. The doc was created, then deleted. Do nothing.
        //   3. The doc has never been created. Create it.
        if let docId = meal.docId {
            do {
                try datastore!.getDocumentWithId(docId)
                print("Skip \(docId) creation: already exists")
                return false
            } catch let error as NSError {
                if (error.userInfo["NSLocalizedFailureReason"] as? String
                        != "not_found") {
                    print("Skip \(docId) creation: already deleted by user")
                    return false
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
        
        return true
    }
    
    func storeSampleMeals() {
        let photo1 = UIImage(named: "meal1")!
        let photo2 = UIImage(named: "meal2")!
        let photo3 = UIImage(named: "meal3")!
        
        let meal1 = Meal(name: "Caprese Salad", photo: photo1, rating: 4, docId: "sample-1")!
        let meal2 = Meal(name: "Chicken and Potatoes", photo: photo2, rating: 5, docId:"sample-2")!
        let meal3 = Meal(name: "Pasta with Meatballs", photo: photo3, rating: 3, docId:"sample-3")!
        
        // Hard-code the createdAt property to get consistent revision IDs. That way, devices that share
        // a common cloud database will not generate conflicts as they sync their own sample meals.
        let comps = NSDateComponents()
        comps.day = 1
        comps.month = 1
        comps.year = 2016
        comps.timeZone = NSTimeZone(abbreviation: "GMT")
        let newYear = NSCalendar.currentCalendar().dateFromComponents(comps)!
        
        meal1.createdAt = newYear
        meal2.createdAt = newYear
        meal3.createdAt = newYear

        let created1 = createMeal(meal1)
        let created2 = createMeal(meal2)
        let created3 = createMeal(meal3)
        
        if (created1 || created2 || created3) {
            print("Sample meals changed; begin push sync")
            sync(.Push)
        }
    }
    
    func loadMealsFromDataStore() {
        let query = ["created_at": ["$gt":""]]
        let result = datastore?.find(query, skip: 0, limit: 0, fields:nil, sort: [["created_at":"asc"]])
        guard result != nil else {
            print("Failed to query for meals")
            return
        }
        
        meals.removeAll()
        result!.enumerateObjectsUsingBlock({ (doc, idx, stop) -> Void in
            if let meal = Meal(aDoc: doc) {
                self.meals.append(meal)
            }
        })
    }
    
    // MARK: Cloudant Sync
    
    func interceptRequestInContext(context: CDTHTTPInterceptorContext) -> CDTHTTPInterceptorContext {
        let appVer: AnyObject = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]!
        let osVer = NSProcessInfo().operatingSystemVersionString
        let ua = "\(userAgent)/\(appVer) (iOS \(osVer)h)"

        context.request.setValue(ua, forHTTPHeaderField: "User-Agent")
        return context
    }
    
    func cloudURL() -> NSURL {
        let credentials = "\(cloudantApiKey):\(cloudantApiPassword)"
        let host = "\(cloudantAccount).cloudant.com"
        let url = "https://\(credentials)@\(host)/\(cloudantDBName)"
        
        return NSURL(string: url)!
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        print("Refresh!")
        sync(.Pull)
    }
    
    func sync(direction: SyncDirection) {
        // Sync local data to or from the central cloud.
        let replication = replications[direction]
        guard replication == nil else {
            print("Ignore \(direction) replication; already running")
            return
        }
        
        let factory = CDTReplicatorFactory(datastoreManager: datastoreManager)
        let job = (direction == .Push)
            ? CDTPushReplication(source: datastore!, target: cloudURL())
            : CDTPullReplication(source: cloudURL(), target: datastore!)
        job.addInterceptor(self)
        
        do {
            replications[direction] = try factory.oneWay(job)
            replications[direction]!.delegate = self
            try replications[direction]!.start()
        } catch {
            print("Error initializing \(direction) sync: \(error)")
            return
        }
        
        print("Started \(direction) sync: \(replications[direction])")
    }
    
    func replicatorDidChangeState(replicator: CDTReplicator!) {
        // The new state is in replicator.state.
    }
    
    func replicatorDidChangeProgress(replicator: CDTReplicator!) {
        // See replicator.changesProcessed and replicator.changesTotal for progress data.
    }
    
    func replicatorDidComplete(replicator: CDTReplicator!) {
        print("Replication complete \(replicator)")
        
        if (replicator == replications[.Pull]) {
            if (replicator.changesProcessed > 0) {
                // Refresh the meals and reflect them in the main thread.
                loadMealsFromDataStore()
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
            
            refreshControl?.endRefreshing()
        } else if (replicator == replications[.Push]) {
            // Stop all active spinners. Note, this does not perfectly reflect the real replication
            // state; however, it is very simple, and it typically works well enough.
            dispatch_async(dispatch_get_main_queue(), {
                for cell in self.tableView.visibleCells as! [MealTableViewCell] {
                    cell.syncIndicator.stopAnimating()
                }
            })
        }
        
        clearReplicator(replicator)
    }
    
    func replicatorDidError(replicator: CDTReplicator!, info: NSError!) {
        print("Replicator error \(replicator) \(info)")
        clearReplicator(replicator)
    }
    
    func clearReplicator(replicator: CDTReplicator!) {
        // Determine the replication direction, given the replicator argument.
        let direction = (replicator == replications[.Push])
            ? SyncDirection.Push
            : SyncDirection.Pull
        
        print("Clear replication: \(direction)")
        replications[direction] = nil
    }
}
