# Start Developing iOS Apps (Swift) - With Cloud Data Sync; Part 1: The Datastore

This walkthrough is a "sequel" to Apple's well-known iOS programming introduction, [Start Developing iOS Apps (Swift)][apple-doc]. Apple's introduction walks us through the process of building the UI, data, and logic of an example food tracker app, culiminating with a section on data persistence: storing the app data as files in the iOS device.

This series picks up where that document leaves off: syncing data between devices, through the cloud, with an offline-first design. You will achieve this using open source tools and the IBM Cloudant service.

This document is the first in the series, showing you how to use the Cloudant Sync datastore (CDTDatastore) for FoodTracker on the iOS device. Subsequent posts will cover syncing to the cloud and other advanced features such as accounts and data management.

## Table of Contents

1. [About the Lessons](#about-the-lessons)
1. [CocoaPods](#cocoapods)
  1. [Learning Objectives](#learning-objectives)
  1. [Install CocoaPods on your Mac](#install-cocoapods-on-your-mac)
  1. [Install Cloudant Sync using CocoaPods](#install-cloudant-sync-using-cocoapods)
  1. [Change from a Project to a Workspace](#change-from-a-project-to-a-workspace)
1. [Compile with Cloudant Sync](#compile-with-cloudant-sync)
  1. [Create the CDTDatastore Bridging Header](#create-the-cdtdatastore-bridging-header)
1. [Store Data Locally with Cloudant Sync](#store-data-locally-with-cloudant-sync)
  1. [Learning Objectives](#learning-objectives-1)
  1. [The Cloudant Document Model](#the-cloudant-document-model)
  1. [Remove NSCoding](#remove-nscoding)
  1. [Initialize the Cloudant Sync Datastore](#initialize-the-cloudant-sync-datastore)
  1. [Deleting the Datastore in the iOS Simulator](#deleting-the-datastore-in-the-ios-simulator)
  1. [Implement Storing and Querying Meals](#implement-storing-and-querying-meals)
  1. [Create Sample Meals in the Datastore](#create-sample-meals-in-the-datastore)


## About the Lessons

These lessons assume that you have completed the [FoodTracker app][apple-doc] from Apple's walkthrough. Begin with the completed sample project from the final lesson: [Persist Data][apple-doc-download].

<img src="https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/Art/8_sim_navbar_2x.png" alt="Image of FoodTracker app" height="559" width="320">

## CocoaPods

The first step is to connect with the broader open source iOS software community by installing free software packages using [CocoaPods][cocoapods]. You will use the CocoaPods repository to integrate the [Cloudant Sync Datastore][cdtdatastore-pod] library.

### Learning Objectives

At the end of the lesson, you’ll be able to:

  1. Install CocoaPods on your Mac
  1. Use CocoaPods to download and integrate CDTDatastore with FoodTracker
  1. Write a bridging header to compile CDTDatastore into FoodTracker

### Install CocoaPods on your Mac

The CocoaPods web site has an excellent page, [Getting Started][cocoapods-getting-started], which covers intalling and upgrading. For your purposes, you will use the most simple, using the command-line `gem` program.

**To install CocoaPods**

  1. Open the Terminal application
    1. Click the Spotlight icon (a magnifying glass) in the Mac OS taskbar
    1. Type "terminal" in the Spotlight prompt, and press return
  1. In Terminal, type this command:

  ```
  sudo gem install cocoapods
  ```

  1. Confirm that CocoaPods is installed with this command:

  ```
  pod --version
  ```

  You should see the CocoaPods version displayed in Terminal:

  ```
  0.39.0
  ```

### Install Cloudant Sync using CocoaPods

To install CDTDatastore as a dependency, create a *Podfile*, a simple configuration files which tell CocoaPods which packages this project needs.

**To create a Podfile**

  1. Choose File > New > File (or press Command-N)
  1. On the left side of the dialog that appears, select Other under iOS.
  1. Select Empty, and click Next.
  1. In the Save As field, type `Podfile`.
  1. The save location defaults to your project directory.

     The Group option defaults to your app name, FoodTracker.

     In the Targets section, make sure both your app and the tests for your app are not selected.
  1. Click Create.

     Xcode creates a file called `Podfile`.

Next, configure CDTDatastore in the Podfile.

**To configure the Podfile**

  1. Open `Podfile`.
  1. Add the following code

     ``` ruby
     platform :ios, '9.1'
     pod "CDTDatastore", '~> 1.0.0'
     ```
  1. Choose File > Save (or press Command-N)

With your Podfile in place, simply run the CocoaPods command in Terminal to install the CDTDatastore pod.

**To install CDTDatastore**

  1. Open Terminal
  1. Change to your project directory, the directory containing your new Podfile. For example,

     ```
     # Your 'cd' command may be different; change to the folder you use.
     cd "FoodTracker - Cloud Data Sync"
     ```
  1. Type this command

     ```
     pod install --verbose
     ```

You will see colorful output from CocoaPods in the terminal.

### Change from a Project to a Workspace

Because you are now integrating FoodTracker with the third-party CDTDatastore library, your project is really a *group* of projects combined into one useful whole. XCode supports this, and CocoaPods has already prepared you for this transition by creating `FoodTracker.xcworkspace` for you&mdash;a *workspace* encompassing both FoodTracker and CDTDatastore.

**To change to your project workspace**

  1. Choose File > Close Window (or press Command-W)
  1. Choose File > Open (or press Command-O)
  1. Select `FoodTracker.xcworkspace` and click Open

You will see a similar XCode view as before, but notice that you now have two projects now.

-![FoodTracker workspace has two projects](img/workspace.png)

Test that everything still works by running your project again (Command-R). It should behave exactly as before; so you know that everything is in its place and working correctly.

## Compile with Cloudant Sync

Your next step is to compile the Food Tracker along with CDTDatastore, the Cloudant Sync library. You will not change any major FoodTracker code yet; however, this will confirm that CDTDatastore and FoodTracker integrate and compile correctly.

### Create the CDTDatastore Bridging Header

CDTDatastore is written in Objective-C. Your FoodTracker is a Swift project. Currently, the best way to integrate these projects together is with a [bridging header][bridging-header]. The bridging header, `CloudantSync-Bridging-Header.h` will tell Xcode to compile CDTDatastore into the final app. ("CloudantSync" is the name of the IBM Cloudant sync service, `CDTDatastore` is its iOS implementation.)

**To create a header file**

  1. Choose File > New > File (or press Command-N)
  1. On the left side of the dialog that appears, select Source under iOS.
  1. Select Header File, and click Next.
  1. In the Save As field, type `CloudantSync-Bridging-Header`.
  1. The save location defaults to your project directory.

     The Group option defaults to your app name, FoodTracker.

  1. In the Targets section, check the FoodTracker target.
  1. Click Create.

     Xcode creates and opens a file called `CloudantSync-Bridging-Header.h`.
  1. Under the line which says `#define CloudantSync_Bridging_Header_h`, insert the following code:

     ``` c
     #import <CloudantSync.h>
     ```

The header file contents are done. But, despite its name, this file is not yet a *bridging header* as far as Xcode cares. The final step is to tell Xcode that this file will serve as the Objective-C bridging header.

**To specify a project bridging header**

  1. Enter the Project Navigator view by clicking the upper-left folder icon (or press Command-1).
  1. Select the FoodTracker project
  1. Currently, only basic build settings are displayed; click All to show all build settings
  1. In the search bar, type "bridging header." You should see **Swift Compiler - Code Generation** and inside it, **Objective-C Bridging Header**.

     ![Finding the bridging header value](img/find-bridging-header.png)
  1. Double-click the empty space in the right column, in the row **Objective-C Bridging Header** (i.e. neither **Debug** nor **Release**, but above them).
  1. A prompt window will pop up. Input the following:

     ```
     FoodTracker/CloudantSync-Bridging-Header.h
     ```
     ![Input the bridging header value](img/input-bridging-header.png)
  1. Press return

Your bridging header is done! Xcode should look like this:

![Final bridging header setup](img/bridging-header.png)

*Checkpoint:* Run your app. This will confirm that the code compiles and runs. While you have not changed any user-facing app code, you have begun the first step to Cloudant Sync by compiling CDTDatastore into your project.

## Store Data Locally with Cloudant Sync

With CDTDatastore compiled and working, the next step is to replace the NSCoder persistence system with CDTDatastore. Currently, in `MealTableViewController.swift`, during initialization, the encoded array of meals is loaded from local storage. When you add or change a meal, the entire `meals` array is encoded and stored on disk. You will replace that system with a document-based architecture&mdash;in other words, each meal will be one record in the Cloudant Sync datastore.

Keep in mind, this first step of using Cloudant Sync *does not use the Internet at all*. The first goal is simply to store app data locally. After that works correctly, you will add cloud sync features. This is the *offline-first* architecture, with Internet access being *optional* to use the app. All data operations are on the local device. (If the device has an Internet connection, then the app will sync its data to the cloud&mdash;covered in the next section.)

### Learning Objectives

At the end of the lesson, you’ll be able to:

  1. Understand the Cloudant document model:
    1. Key-value storage for simple data types
    1. Attachment storage for binary data
    1. The document ID and revision ID
  1. Store meals in the Cloudant Sync datastore
  1. Query for meals in chronological order, from the datastore

### The Cloudant Document Model

Let's begin with a discussion of Cloudant basics. The *document* is the primary data model of all IBM Cloudant databases, not only Cloudant Sync for iOS, but also for Android, as well as the Cloudant hosted database. This makes sense, because all databases can replicate to and from each other (and also to and from [Apache CouchDB][couchdb]).

A document, often called a *doc*, is a *body* of key-value data. But do not think "Microsoft Office document"; think "JSON object." A document is a JSON object: keys (strings) can have values (Ints, Doubles, Bools, Strings, as well as nested Arrays and Dictionaries).

Documents can also contain binary blobs, called *attachments*. You can add, change, or remove attachments in a very similar way as you would add, change, or remove key-value data in a doc.

All documents always have two pieces of metadata, used to manage them. The *document ID* (sometimes called *_id* or simply *id*) is a unique string identifying the doc. You use the ID to find, read, and write a document.

The *revision ID* (sometimes called *_rev* or *revision*) is a string generated by the datastore which tracks when the doc changes. The revision is mostly used interally by the datastore, especially to facilitate replication. In practice, you need to remember a few simple things about revisions:

* The revision ID changes every time you store a change to a document
* When you update a document, you provide the current revision ID to the datastore, and the datastore will return to you the *new* revision ID of the new document
* When you create a document, you *do not* provide a revision ID (since there is no "current" document with a "current" revision ID to provide)

Finally, note that deleting a document is actually an update, with metadata set to indicate deletion (sometimes called a document "tombstone"). Since a delete is an update just like any other, the deleted document will have its own revision ID.

With this in mind, consider: how will the sample meals work? At first, you might think to create meals documents when the app starts. That will work correctly the first time the user runs the app; however, if the user changes or deletes the sample meals, *those changes must persist*. For example, if the user deletes the sample meals and then restarts the app later, those meals must remain deleted.

To support this requirement, you will use the "tomstones" feature of documents. This will be the basic design:

  * Each meal is a single document, which will contain the meal name, its rating, and a photo attachment.
  * To initialize the first three meals, simply attempt to create the documents, with no prior revision ID
    * If the meals are not yet in the datastore, they will be created normally;
    * If the meals already exist, CDTDatastore will return a "conflict" result, which you will ignore. Even after the user updates or deletes a sample meal, its tombstone will persist in the datastore.

Now, you can put this understanding into practice by transitioning to Cloudant Sync for local app data storage.

### Remove NSCoding

Begin cleanly by removing the current NSCoding system from the model and the table view controller.

**To remove NSCoding from the model**

  1. Open `Meal.swift`
  1. Find the class declaration, which says:

     ``` swift
     class Meal: NSObject, NSCoding {
     ```
  1. Remove the word `NSCoding` and also the comma before it, making the new class declaration look like this:

     ``` swift
     class Meal: NSObject {
     ```
  1. Delete the comment line, `// MARK: NSCoding`.
  1. Delete the method below that, `encodeWithCoder(_:)`.
  1. Delete the method below that, `init?(coder aDecoder: NSCoder)`.

Next, remove NSCoding from the table view controller.

**To remove NSCoding from the table view controller**

  1. Open `MealTableViewController.swift`
  1. Find the method `viewDidLoad()`, and delete the comment `// Load any saved meals`... and also the if/else code below it:

     ``` swift
     // Load any saved meals, otherwise load sample data.
     if let savedMeals = loadMeals() {
         meals += savedMeals
     } else {
         // Load the sample data.
         loadSampleMeals()
     }
     ```
  1. Delete the method `loadSampleMeals()`, which is immediately beneath the `viewDidLoad()` method.
  1. Find the method `tableView(_:commitEditingStyle:forRowAtIndexPath:)` and delete the line of code `saveMeals()`.
  1. Find the method `unwindToMealList(_:) and delete its last two lines of code: a comment, and a call to `saveMeals()`.

     ``` swift
     // Save the meals.
     saveMeals()
     ```
  1. Delete the comment line, `// MARK: NSCoding`
  1. Delete the method below that, `func saveMeals()`.
  1. Delete the method below that, `func loadMeals()`.

*Checkpoint:* Run your app. The app will obviously lose some functionality: loading stored meals, and creating the first three sample meals; although you can still create, edit, and remove meals (but they will not persist if you quit the app). That is okay. In the next step, you will restore these functions using Cloudant Sync instead.

### Initialize the Cloudant Sync Datastore

Now you will add loading and saving back to the app, using the Cloudant Sync datastore. A meal will be a document, with its name and rating stored as key-value data, and its photo stored as an attachment.

Begin with the Meal model, the file `Meal.swift`. You will add a new initialization method which can create a Meal object from a document. In other words, the `init()` method will set the meal name and rating from the document key-value data; and it will set the meal photo from the document attachment.

Representing a Meal as a Cloudant Sync document requires few changes besides the initialization function. The only change the the actual model is to add a variable for the underlying document ID. By remembering a meal's document ID, you will be able to change that doc when the user changes the meal (e.g. by changing its rating, its name, or its photo).

**To add Cloudant Sync datastore support**

  1. Open `Meal.swift`
  1. In `Meal.swift`, in the section `MARK: Properties`, append this line:

     ``` swift
     var docId: String?
     ```
  1. In `Meal.swift`, edit the `init?` method to accept a docId as a final argument, and to set the docId property. When you are finished, the method will look like this:

     ``` swift
     init?(name: String, photo: UIImage?, rating: Int, docId: String?) {
         // Initialize stored properties.
         self.name = name
         self.photo = photo
         self.rating = rating
         self.docId = docId

         super.init()

         // Initialization should fail if there is no name or if the rating is negative.
         if name.isEmpty || rating < 0 {
             return nil
         }
     }
     ```

Now add a convenience initializer. This is a method which accepts a Cloudant Sync document, and creates a Meal object.

**To create a convenience initializer**

  1. Open `Meal.swift`
  1. In `Meal.swift`, below the `init?()` method, add the following code:

     ``` swift
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
     ```

That's it for the model. The Meal class now tracks both its underlying document ID, and it supports convenient initialization directly from a Cloudant Sync datastore document (or simply, a "doc").

Since the Meal model initializer has a new `docId: String?` parameter, you will need to update the one bit of code which initializes Meal objects, in the Meal view controller.

**To update the meal view controller**

  1. Open `MealViewController.swift`
  1. In `MealViewController.swift`, find the function `prepareForSegue(_:sender:)` and change the last section of code to this:

     ``` swift
     // Set the meal to be passed to MealListTableViewController after the unwind segue.
     meal = Meal(name: name, photo: photo, rating: rating, docId: nil)
     ```

Now the model has been updated to work from Cloudant Sync documents.

To put these new features to work, all that remains is to use the datastore from the Meal table view controller. Begin by initializing the datastore and data.

**To initialize the datastore**

  1. Open `MealTableViewController.swift`
  1. In `MealTableViewController.swift`, find the `MARK: Properties` section, append the following code beneath the line `var meals = [Meal]()`:

     ``` swift
     var datastoreManager: CDTDatastoreManager?
     var datastore: CDTDatastore?
     ```
  1. In `MealTableViewController.swift`, append the following code to the method `viewDidLoad()`:

     ``` swift
     // Initialize the Cloudant Sync local datastore.
     let fileManager = NSFileManager.defaultManager()

     let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory,
         inDomains: .UserDomainMask).last!

     let storeURL = documentsDir.URLByAppendingPathComponent("foodtracker-meals")
     let path = storeURL.path

     do {
         datastoreManager = try CDTDatastoreManager(directory: path)
         datastore = try datastoreManager!.datastoreNamed("meals")
     } catch {
         fatalError("Failed to initialize datastore")
     }
     ```

### Deleting the Datastore in the iOS Simulator

Sometimes during development, you may want to delete the datastore and start over. There are several ways to do this, for example, by deleting the app from the simulated device.

However, here is a quick command you can paste into the terminal. It will remove the Cloudant Sync database. When you restart the app, the app will initialize a new datastore and behave as if this was its first time to run. For example, it will re-create the sample meals again.

**To delete the datastore from the iOS Simulator**

    rm -i -rv $HOME/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Documents/foodtracker-meals

This command will prompt you to remove the files. If you are confident that the command is working correct, you can omit the `-i` option.

### Implement Storing and Retrieving from the Datastore

With the datastore initialized, you need to write methods to store and retrieve meal documents from the datastore. Of course, this is the heart of this project. Fortunately, this step requires only a few methods to interact with the datastore; and subsequently you will enjoy all the benefits the Cloudant Sync datastore brings, like offline-first operation and cloud syncing.

Begin by creating a code marker for the new Cloudant Sync datastore methods.

**To create a code marker for your code**

  1. Open `MealTableViewController.swift`
  1. In `MealTableViewController.swift`, find the last method in the class, `unwindToMealList(_:)`
  1. Below that method, add the following:

  ``` swift
  // MARK: Datastore
  ```
  1. This will be the section of the code where you implement all Cloudant Sync datstore functionality.

Next, write the method to save a meal to the datastore. The method will support all of these scenarios:

  * **When creating sample meals:** Store the meal doc, *without* a revision ID, but *with* a hard-coded document ID (e.g. `"meal1"`, `"meal2"`, and `"meal3"`). This will have two possible outcomes:
    1. A document with that ID is not yet present, so creation succeeds, *or*
    1. A document with that ID is already present. Cloudant Sync will return a "conflict" error, which the method can ignore.
  * **When creating meals for the user:** Attempt to create the meal doc, *without a revision ID*, and *without* specifying a doc ID. Since you do do not specify a doc ID, the datastore will use a random UUID, and that will ensure that  and *without* a prior revision, because of course these are brand new records for the database
  * **When updating a meal:** You *will* specify the doc ID (to tell the datastore which record to update).
    1. First first fetch the current record by ID, in order to get its current revision
    1. Then, update its data (rating, name, and photo), and save the updates

**To save meals to the datastore**

  1. Open `MealTableViewController.swift`
  1. In `MealTableViewController.swift`, in the section `MARK: Datastore`, add a new method:

     ``` swift
     func saveMeal(meal: Meal) {
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
     ```

That's it! The most complex 

### Create Sample Meals in the Datastore

Now is time to create sample meal documents during app startup. To review, the initialization process will work this way:

  1. The app starts, and quickly runs `viewDidLoad()` in the `MealTableViewController` class.
  1. Attempt to create the sample meals, with hard-coded document IDs.
    1. If the meals had never been created, they will be added to the datastore
    1. If the meals had already been created (even if they have been subsequently deleted), the creation will quietly fail
  1. In any case, read all meals from the datastore into memory, for display to the user.

**To create sample meals during app startup**

1. Open `MealTableViewController.swift`
1. In `MealTableViewController.swift`, in the section `MARK: Datastore`, add a new method:

   ``` swift
   func storeSampleMeals() {
       let photo1 = UIImage(named: "meal1")!
       let photo2 = UIImage(named: "meal2")!
       let photo3 = UIImage(named: "meal3")

       let meal1 = Meal(name: "Caprese Salad", photo: photo1, rating: 4, docId: "meal1")!
       let meal2 = Meal(name: "Chicken and Potatoes", photo: photo2, rating: 5, docId:"meal2")!
       let meal3 = Meal(name: "Pasta with Meatballs", photo: photo3, rating: 3, docId:"meal3")!

       saveMeal(meal1, create:true)
       saveMeal(meal2, create:true)
       saveMeal(meal3, create:true)
   }
   ```
1. In `MealTableViewController.swift`, in the method `viewDidLoad()`, add this code:

  ``` swift
  // The datastore is now ready. Next, initialize the sample meals.
  storeSampleMeals()
  ```


## Sync with IBM Cloudant

[END]: ------------------------------------------------

[apple-doc]: https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html
[apple-doc-download]: https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/Lesson10.html#//apple_ref/doc/uid/TP40015214-CH14-SW3
[bridging-header]: https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html
[cdtdatastore-pod]: https://cocoapods.org/pods/CDTDatastore
[cocoapods]: https://cocoapods.org/
[cocoapods-getting-started]: https://guides.cocoapods.org/using/getting-started.html
[couchdb]: http://couchdb.apache.org
