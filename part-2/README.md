# Start Developing iOS Apps (Swift) with Cloud Sync; Part 2: Sync to Cloudant

This walkthrough is a sequel to Apple's well-known iOS programming introduction, [Start Developing iOS Apps (Swift)][apple-doc]. Apple's introduction walks us through the process of building the UI, data, and logic of an example food tracker app, culiminating with a section on data persistence: storing the app data as files in the iOS device.

This series picks up where that document leaves off: syncing data between devices, through the cloud, with an offline-first design. You will achieve this using open source tools and the IBM Cloudant service.

This document is the second in the series, showing you how to sync the app data to Cloudant. You can also review the previous post in the series, [Part 1: The Datastore][part-1].

## Getting Started with FoodTracker

![The FoodTracker main screen](media/FoodTracker@2x.png "; figure")

This document assumes that you have completed [Part 1: The Datastore][part-1] of the series. If you have completed that walkthrough, you may continue with your FoodTracker project.

Alternatively, you can download the prepared project from the [Part 1 Code download][part-1-download] and begin there. Extract the zip file, `FoodTracker-Cloudant-Sync-1.zip`, browse into its folder with Finder, and double-click `FoodTracker.xcworkspace`. That will open the project in Xcode. Run the app (Command-R) and confirm that it works correctly. If everything is in order, proceed with these instructions.

## Getting Started with Cloudant

In this section you will create a free IBM Cloudant account. This will be the cloud database with which the FoodTracker app will sync its data. If you already have a Cloudant account then you can use your existing account. If you plan on using your existing Cloudant account then skip to the "[Prepare Cloudant for the FoodTracker App][prepare-service]" section of this tutorial.

### Create a Free IBM Cloudant Account

Getting started with IBM Cloudant is free and easy. Begin by signing up on [Cloudant.com][cloudant-home].

![The Cloudant home page](media/cloudant-01-home@2x.png '; border')

Click the red "Sign Up" button and fill out the sign-up form. Your *Username* will be in every URL you use. For example, the user *foodtracker* will be accessible at `https://foodtracker.cloudant.com`. This *foodtracker* account is used throughout the examples in this tutorial. You will replace *foodtracker* with your unique Cloudant username in these examples.

Complete the form, read the terms of service, and then click the red button, "I agree, sign me up."

![Signing up with Cloudant](media/cloudant-02-sign-up@2x.png '; border')

Alternatively, you can create a [Cloudant service instance within IBM Bluemix](https://console.ng.bluemix.net/catalog/services/cloudant-nosql-db/). You can [sign up for a free trial](https://console.ng.bluemix.net/registration) if you don't already have a Bluemix account. Note that a Cloudant service instance created within Bluemix is assigned a Cloudant username that is automatically generated at the time of service instantiation.

### The Cloudant Dashboard

![The Cloudant Dashboard home](media/dashboard-01-home@2x.png '; figure')

When sign-up is complete, your browser will display the *dashboard*.

The dashboard is the web interface to manage your data.

**Use the dashboard to observe and verify FoodTracker's behavior.** This is a major advantage to using Cloudant: you have a simple and pleasant tool to help you do your job. In this walkthrough, you will frequently use the dashboard in conjunction with the iOS Simulator.

### Prepare Cloudant for the FoodTracker App

Use the dashboard to prepare the database for FoodTracker. To work correctly, FoodTracker will need a few things:

1. A *database*, to store data,
1. An *API key*, to authenticate, and
1. *Permission* to use the database

#### The Database

Begin by creating the database for FoodTracker. At the top of the dashboard is the "Create Database" button. Click it, and a drop-down form will appear. Input the database name in all lower case, underscore format: `food_tracker`.

![Create a Cloudant database](media/dashboard-02-create-db@2x.png '; border')

Welcome to *food_tracker*! You have a brand-new, clean database for FoodTracker to sync with.

![Database creation complete!](media/dashboard-02_1-db_created@2x.png '; figure')

In Cloudant, the database is foundational to an application: it is the "observable universe" of the application. The vast majority of the Cloudant API is around database operations. Access control, data validation, and queries are scoped to a specific database and the data stored within that database.

One common approach that we see used is the one-database-per-user pattern. With this approach, each user is given their own Cloudant database in which all of the data applicable to this one user is stored. Since there is no limit to the number of databases that you can create within your Cloudant account, the one-database-per user approach can scale as you add more app users.

To review about names:

* Your *server* is named after your account. For example, the account in this example, `foodtracker`, is available at `https://foodtracker.cloudant.com/`.
* Your *database* is the storage place for FoodTracker data. For example, the database used in this document, `food_tracker`, is named after the iOS app. It is available at `https://foodtracker.cloudant.com/food_tracker`.
* Your **server name will be different** from this document
* Your **database name will be the same** as this document.

To see your database, use the dashboard. From the "Databases" tab, click the link to *food_tracker*.

![The new meals database](media/dashboard-03-meals-db@2x.png '; border')

#### The API Key

Now, you must create an *API key*. An API key is a username and password pair generated by Cloudant. The FoodTracker app will use the API key credentials to access the data stored in Cloudant.

**To create an API key**

1. Open the the *food_tracker* database in the dashboard.
1. In the *food_tracker* database, click the "Permissions" link. ![The API Key manager](media/dashboard-03_1-api-key-page@2x.png '; border')
1. In the Permissions tab, click the "Generate API key" button and wait for Cloudant to generate a new key.

  ![Generating and API Key](media/dashboard-03_2-generating-key@2x.png '; border')
1. Cloudant will tell you when the key is ready.

  ![A new API key, ready for use](media/dashboard-03_3-new-api-key@2x.png '; border')

**Copy the API key and password now.** You will need to use these to connect the FoodTracker iOS app to Cloudant.

#### API Permission

The final step is to grant read, write, and replication access to your API key.

**To grant permissions to an API key**

1. In the Permissions tab, find the access control settings at the top of the page.
1. Find the row for your new API key, for example, *facringediftedgentlerrad*.
1. Check the columns for *Reader*, *Writer*, and *Replicator*.
1. Ensure that the column for *Admin* is not checked.

![Grant permissions to the new API key](media/dashboard-05-permissions@2x.png '; border')

### Confirm API Access

Now is the time to stop and confirm that everything is ready with your Cloudant service. The best way to do this on a Mac is to open Terminal and use `curl` (curl can also run on a number of other platforms). When you "curl" Cloudant, you will immediately see whether everything is working, and you can quickly determine what might be wrong. Begin by running the *Terminal* application.

The command below will authenticate to Cloudant and display the data. Notice that the username and password are inserted in the URL. The username is followed by `:`, then the password, then `@`, and then the usual hostname and path. When you paste this command into Terminal, **change the values to reflect your own server**.

    curl https://facringediftedgentlerrad:ee4c30dbd2f7457ccf6804f9536ad1a79f0ea9ad@foodtracker.cloudant.com/food_tracker/_all_docs

![Confirm API access using cURL](media/confirm-api-access@2x.png '; border')

If you **see an empty listing of documents**, you have completed everything.

Good job! Cloudant is fully prepared. You are ready to move to the next sections, where you will actually add the ability for the FoodTracker app to sync with Cloudant.

## Troubleshooting Tip: Deleting Data

When working with data syncing features, you may wish to delete some data, so that you can start over and try again.

These are example commands you can paste into *Terminal*. These commands will help you to easily remove data from either Cloudant or your iOS Cloudant Sync datastore. As you work on syncing you may notice that documents will often move between the cloud and the device (which is the very nature of syncing data). So, you may sometimes wish to delete *both* data sets, to truly start from the beginning.

### Deleting the iOS Datastore

This will remove the Cloudant Sync database. When you restart the app, the app will initialize a new datastore and behave as if this was its first time to run. For example, it will re-create the sample meals again.

**To delete the datastore from the iOS Simulator**

    rm -i -rv $HOME/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Documents/foodtracker-meals

This command will prompt you to remove the files. If you are confident that the command is working correct, you can omit the `-i` option.

### Deleting a Cloudant database

This procedure will delete the *food_tracker* database in the cloud, removing everything in it. Once deleted, you will want to re-create a new database by following the [database preparation procedure][prepare-service].

**To delete and re-create the database in Cloudant**

1. Open the the *food_tracker* database in the dashboard.
1. In the *food_tracker* database, click the settings button, ![The settings icon](media/settings@2x.png), which looks like a gear.
1. Click the "Delete" button with the rubbish bin icon. ![The delete-database button](media/delete-db@2x.png '; border')
1. Since this is a significant and permanent change, you must confirm your request by inputing the database name, `food_tracker`, into the form. Press "Delete".

![Confirm deleting a database](media/deleting-db@2x.png '; border')

Finally, [prepare a new database][prepare-service] to replace this one. If your FoodTracker already connects to Cloudant, then you have two choices:

* Either paste your old API key and press the "Grant Rights" button.
* Or, generate a new API key, then update your API key and password in the app source code.

## Push Replication

Now comes the fun part! The first step is to *push* data from the device up to Cloudant. When you finish this section, all data updates will syncronize to your central Cloudant service: both when the user creates new meals, and also when the user modifies existing meals (for example, changing the meal photo, or its star rating).

### First Steps: Set the User-Agent

Most iOS apps should identify themselves properly in the HTTP *User-Agent* header. Typically, the User-Agent value should specify the software name version, and also the operating system version. In this example, we will hard-code the sofwtare name, FoodTracker, and extract the version from the sofware bundle (managed by Xcode).

Defining a User-Agent a very useful habit to develop. For example: remember that this FoodTracker app, and Cloudant Sync is also compatible with Apache CouchDB 2.0. In the future, if you wish to manage your own CouchDB server, or to use a hybrid Cloudant-and-CouchDB system, that will be a straightforward procedure. However, a key part of such a system will be the User-Agent identification coming from all of your deployed apps.

In other words: Set the User-Agent now, just in case. It is easy to do, and you will thank yourself in the future.

**To set the user-agent string**

1. Open `MealTableViewController.swift`
1. Near the top of `MealTableViewController.swift`, find the "Properties" section, where `meals`, `datastoreManager`, and `datastore` are declared.
1. Insert the following code beneath that:

  ``` swift
  // MARK: Cloudant Settings

  let userAgent = "FoodTracker"
  ```
1. Scroll down to the bottom of the class.
1. Below the method `func storeSampleMeals()`, insert the following code:

  ``` swift
  // MARK: Cloudant Sync

  // Intercept HTTP requests and set the User-Agent header.
  func interceptRequestInContext(context: CDTHTTPInterceptorContext)
      -> CDTHTTPInterceptorContext {
          let info = NSBundle.mainBundle().infoDictionary!
          let appVer = info["CFBundleShortVersionString"]
          let osVer = NSProcessInfo().operatingSystemVersionString
          let ua = "\(userAgent)/\(appVer) (iOS \(osVer)"

          context.request.setValue(ua,
              forHTTPHeaderField: "User-Agent")
          return context
  }
  ```
1. Scroll to the top of the class and find the class declaration line.
1. Append the `CDTHTTPInterceptor` interface, so that the declaration now looks as follows:

  ``` swift
  class MealTableViewController: UITableViewController,
      CDTHTTPInterceptor {
  ```

Checkpoint: **Run your app.** Of course, the app's behavior will not change; however this is a good place to catch any programming errors.

### Preparing to Sync

The next step is also straightforward. You will define the information that FoodTracker will need to connect to Cloudant: the account name, the login credentials, etc.

Another important property is the `replications` dictionary, which will keep track of pending replications. Replications are not instant. It takes time to transfer data and images to and from the central server. So, FoodTracker will remember which replications are currently running. If the code attempts to run a duplicate replication (for example, it wants to push when an existing push is already in progress), then FoodTracker can simply ignore the second sync call. The execution will work like this:

1. The user creates or modifies a meal.
2. FoodTracker begins the push replication procedure.
3. `replications[.Push]` is `nil`. No push replications are in-flight, so:
  1. A new replication begins.
  2. FoodTracker stores this replication object in `replications[.Push]`.
4. Before the replication completes, the user makes another change.
5. FoodTracker again automatically begins a the push replication procedure.
6. But this time, it sees that `replications[.Push]` already has a replication underway, so it *does nothing*.
7. The original push replication will see the latest change from step 4 and includes that in the replication. (Thanks, CDTDatastore!)
8. Once the replication is complete, FoodTracker sets `replications[.Push]` to `nil`, indicating that the next replication can proceed.

Of course, the same logic will apply to pull replications.

**To define key Cloudant Sync information**

1. In `MealTableViewController.swift`, scroll to the section, `MARK: Properties`.
1. Below the `datastoreManager` and `datastore` properties, insert the following code:

  ``` swift

  // Define two sync directions: push and pull.
  // .Push will copy local data from FoodTracker to Cloudant.
  // .Pull will copy remote data from Cloudant to FoodTracker.
  enum SyncDirection {
      case Push
      case Pull
  }

  // Track pending .Push and .Pull replications here.
  var replications = [SyncDirection: CDTReplicator]()
  ```
1. Scroll to the section, `MARK: Cloudant Settings`.
1. Find the line where you defined `userAgent`.
1. Below that line, insert the following code:

  ``` swift

  // NOTE: You must change these values for your own application.
  let cloudantAccount = "foodtracker"
  let cloudantDBName = "food_tracker"
  let cloudantApiKey = "facringediftedgentlerrad"
  let cloudantApiPassword = "ee4c30dbd2f7457ccf6804f9536ad1a79f0ea9ad"
  ```

  Remember when you copied down your API key credentials? Paste them here, as the values for `cloudantApiKey` and `cloudantApiPassword`. If you haven't got them handy, you can simply [create a new API key](#the-api-key) (and remember to grant credentials too).

Checkpoint: **Run your app.** Again, the app's behavior will not change. But when the app compiles and runs, you will know you haven't got any errors or typos.

### Managing a replication: CDTReplicatorDelegate

A replication to or from Cloudant will take a certain amount of time, while data and images are copied over the Internet. Also, various noteworthy events may happen during replication, for example: some progress is made, or the replication has completed, or the replication has encountered an error. To handle these events, you class must implement the `CDTReplicatorDelegate` interface. Once that groundwork is done, it is a simple matter to keep an eye on replications as they transpire.

For now, you will implement the interface, but the methods will do little except logging the replication status, and clearing the `replications` dictionary when a replication is done.

**To implement the CDTReplicatorDelegate interface**

1. In `MealTableViewController.swift`, find the `MealTableViewController` class declaration line.
1. Append the `CDTReplicatorDelegate` interface, so that the declaration now looks as follows:

  ``` swift
  class MealTableViewController: UITableViewController,
      CDTHTTPInterceptor, CDTReplicatorDelegate {
  ```
1. Go to the very bottom of the class, and append the relevant functions.
  ``` swift
  func replicatorDidChangeState(replicator: CDTReplicator!) {
      // The new state is in replicator.state.
  }
  
  func replicatorDidChangeProgress(replicator: CDTReplicator!) {
      // See replicator.changesProcessed and replicator.changesTotal
      // for progress data.
  }
  
  func replicatorDidComplete(replicator: CDTReplicator!) {
      print("Replication complete \(replicator)")

      if (replicator == replications[.Pull]) {
          if (replicator.changesProcessed > 0) {
              // Reload the meals, and refresh the UI.
              loadMealsFromDatastore()
              dispatch_async(dispatch_get_main_queue(), {
                  self.tableView.reloadData()
              })
          }
      }

      clearReplicator(replicator)
  }
  
  func replicatorDidError(replicator: CDTReplicator!, info:NSError!) {
      print("Replicator error \(replicator) \(info)")
      clearReplicator(replicator)
  }
  
  func clearReplicator(replicator: CDTReplicator!) {
      // Determine the replication direction, given the replicator
      // argument.
      let direction = (replicator == replications[.Push])
          ? SyncDirection.Push
          : SyncDirection.Pull
      
      print("Clear replication: \(direction)")
      replications[direction] = nil
  }
  ```

You are encouraged to flesh out the empty methods, `replicatorDidChangeState(_:)` and `replicatorDidChangeProgress(_:)`! But, for now, these examples will keep them empty, for simplicity.

Checkpoint: **Run your app.** The app's behavior will not change. But when the app compiles and runs, you will know you haven't got any errors or typos.

### The Heart of Replication: The Sync Method

Everything is now in place. Now, you will implement the method to sync to Cloudant. The method takes one argument, indicating whether to copy local data to Cloudant (`.Push`), or to copy remote data from Cloudant (`.Pull`). The method will detect if the user triggers a concurrent replication (one which would begin before the previous one has finished), and it will simply do nothing.

**To implement Cloudant Sync replication**

1. In `MealTableViewController.swift`, scroll to the bottom of the file, in the section, `MARK: Cloudant Sync`
1. Below the method `interceptRequestInContext(context: CDTHTTPInterceptorContext)`, append the following code:

  ``` swift
  // Return an NSURL to the database, with authentication.
  func cloudURL() -> NSURL {
      let credentials = "\(cloudantApiKey):\(cloudantApiPassword)"
      let host = "\(cloudantAccount).cloudant.com"
      let url = "https://\(credentials)@\(host)/\(cloudantDBName)"

      return NSURL(string: url)!
  }

  // Push or pull local data to or from the central cloud.
  func sync(direction: SyncDirection) {
      let existingReplication = replications[direction]
      guard existingReplication == nil else {
          print("Ignore \(direction) replication; already running")
          return
      }

      let factory = CDTReplicatorFactory(
          datastoreManager: datastoreManager)

      let job = (direction == .Push)
          ? CDTPushReplication(source: datastore!, target: cloudURL())
          : CDTPullReplication(source: cloudURL(), target: datastore!)
      job.addInterceptor(self)

      do {
          // Ready: Create the replication job.
          replications[direction] = try factory.oneWay(job)

          // Set: Assign myself as the replication delegate.
          replications[direction]!.delegate = self

          // Go!
          try replications[direction]!.start()
      } catch {
          print("Error initializing \(direction) sync: \(error)")
          return
      }

      print("Started \(direction) sync: \(replications[direction])")
  }
  ```

Checkpoint: **Run your app.** The app's behavior will not change. But when the app compiles and runs, you will know you haven't got any errors or typos.

That is it for the heavy lifting and the "do-nothing" checkpoints! From this point forward, expect to see very cool features emerge.

### Push to Cloudant When a Change is Made

When should FoodTracker push to Cloudant? Well, first of all, recall that triggering a push very frequently is not a problem. Only one replication per direction (push or pull) will be running at a time. After it completes, if FoodTracker replicates again, that relpication will complete very quickly, since all the data is already synced.

Therefore, it is prudent to call `sync(.Push)` any time the local datastore has changed:

1. After the sample meals are created
1. After the user deletes a meal
1. After the user edits or creates a meal

To do this, you must modify `createMeal(_:)` so that it notifies the caller whether the datastore has changed at all. (Sometimes it can no-op to avoid creating duplicate sample meals.) Change this method to return `true` or `false`, where `true` effectively means *time to push to Cloudant*.

**To replicate to Cloudant (Push) when local data changes**

1. In `MealTableViewController.swift`, in the section **Datastore**, go to the method `createMeal(_:)`.
1. Modify its signature to look as follows:

  ``` swift
  func createMeal(meal: Meal) -> Bool {
  ```
1. Modify both early `return` calls to return `false`, indicating that no change was made. The code in the first `if` block will look as follows:

  ``` swift
  do {
      try datastore!.getDocumentWithId(docId)
      print("Skip \(docId) creation: already exists")
      return false
  } catch let error as NSError {
      if (error.userInfo["NSLocalizedFailureReason"] as? String != "not_found") {
          print("Skip \(docId) creation: already deleted by user")
          return false
      }
      
      print("Create sample meal: \(docId)")
  }
  ```
1. At the bottom of the method, after the do/catch block, append one `return true` statement, indicating that a change was made. The code will look as follows:

  ``` swift
  do {
      let result = try datastore!.createDocumentFromRevision(rev)
      print("Created \(result.docId) \(result.revId)")
      
      // Remember the new ID assigned by the datastore.
      meal.docId = result.docId
  } catch {
      print("Error creating meal: \(error)")
  }

  return true
  ```
1. In the section **Table view data source**, go to the method `tableview(_:commitEditingStyle:forRowAtIndexPath:)`.
1. In the first `if` block, add a call to `sync(.Push)`. The code will look as follows:

  ``` swift
  if editingStyle == .Delete {
      // Delete the row from the data source
      let meal = meals[indexPath.row]
      deleteMeal(meal)
      meals.removeAtIndex(indexPath.row)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      
      // Push this deletion to Cloudant.
      sync(.Push)
  ```
1. In the section **Navigation**, go to the method `unwindToMealList(_:)`.
1. Below the `else` block, insert a call to the `sync()` method. The code will look as follows:

  ``` swift
  } else {
      // Add a new meal.
      let newIndexPath = NSIndexPath(forRow: meals.count, inSection: 0)
      meals.append(meal)
      tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Bottom)
      createMeal(meal)
  }
  
  // Push this edit or creation to Cloudant.
  sync(.Push)
  ```
1. In the section **Datastore**, go to the method `storeSampleMeals()`.
1. At the bottom of the method are three calls to `createMeal()`. Delete those lines and replace them with the following code:

  ``` swift
  let created1 = createMeal(meal1)
  let created2 = createMeal(meal2)
  let created3 = createMeal(meal3)
  
  if (created1 || created2 || created3) {
      print("Sample meals changed; begin push sync")
      sync(.Push)
  }
  ```

Checkpoint: **Run your app.** The app's *outward* behavior will not change; however, it is patiently waiting for a reason to sync to Cloudant.

Because the sample meals already existed (a one-off situation the app will not encounter in the real world), it has not yet pushed anything. But, you can trigger a push by making any change. Try changing the star rating of the Caprese salad.

Remember, a replication will copy *everything* in the datastore. It will bring Cloudant current, reflecting the *all documents*, not one specific document. So, when you make one change to a meal, Cloudant Sync will sync *all* meals to Cloudant, because none had been on the server previously. But if you make a subsequent change, Cloudant Sync will know to copy only that one document. This is the magic of Cloudant Sync, really. It transfers the minimum amount of data to synchronize the *entire datastore*.

Be sure to watch the console log in Xcode. You will see printouts indicating the replication progress, and when it has finished.

![Push replication log](media/push-01-log@2x.png)

### Confirm Replication in the Cloudant Dashboard

Open your web browser to admire your work! Log in to Cloudant and open the `food_tracker` database. You will see the three sample documents.

![Pushed data, document listing](media/push-02-document-list@2x.png)

Click the edit icon (a pencil) in the upper right of a document. This will open a detailed view of that document. Here, you will see the meal data. Doesn't it seem so accessible in JSON format, from a web browser? There is the name (`"name":"Caprese Salad"`). There is the rating (`"rating":4`). What could be simpler?

![Pushed data, document detail](media/push-03-document-detail@2x.png)

And finally, click "View Attachments" and select `photo.jpg`. There is the meal. Congratulations! You have synced an iOS app to the cloud!

![Pushed data, photo attachment](media/push-04-photo@2x.png)

## Pull Replication

By now, you may have a strong urge to *modify* the meal data from the Cloudant dashboard. However, if you do so, those changes will not be reflected in FoodTracker. To accomplish that, you must first implement *pull replication*, so that FoodTracker will download updates from Cloudant.

Would you believe, this will take a single line of code?

### Sync on App Start

In future posts in this series, you will learn to replicate from Cloudant at certain times (for example, when the user executes a well-known "pull to refresh" gesture). However, for now, the easiest thing to do is to pull from Cloudant when the app starts.

**To replicate from Cloudant (Pull) when FoodTracker starts**

1. In `MealTableViewController.swift`, go to the method `viewDidLoad()`.
1. At the bottom of the method, after the call to `initDatastore()`, append the following code:

  ``` swift

  // Immediately pull changes from Cloudant.
  sync(.Pull)
  ```

Checkpoint: **Run your app.** Keep an eye on the console log in Xcode. You will see a *Pull* replication begin, and then quickly complete (because there is no data needing to be copied).

### Confirm Pull Sync

Open your web browser, log in to Cloudant, enter the `food_tracker` database, and open a meal document. Make a change. For example, change the `"name"` or `"rating"` of a meal. (Be careful not to change types. The name is a string; the rating is an integer. You have not implemented data validation yet, so if you are careless, you might get bad data into FoodTracker, where it is less forgiving than your web browser.)

Save your changes.

Now, close and restart FoodTracker. Note the replication logs. When replication is complete (it should be quick), notice your changes reflected in the app. What do you think? Pretty fancy!

## Next Steps: User Interface

## Conclusion

Congratulations! XXX Explain what has been accomplished

XXX Tease the next section

## Download This Project

To see the completed sample project for this lesson, download the file and view it in Xcode.

[Download File][code-download]

## XXX Unresolved To-Dos

Is there any good or official documentation about using the dashboard?

Crop the stupid drop shadow on the screenshots

Produce the download .zip file.

[END]: ------------------------------------------------

[confirm-api]: #confirm-api-access
[prepare-service]: #prepare-cloudant-for-the-foodtracker-app

[apple-doc]: https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html
[cloudant-home]: https://cloudant.com/
[code-download]: media/FoodTracker-Cloudant-Sync-2.zip
[part-1]: https://developer.ibm.com/clouddataservices/2016/01/25/start-developing-ios-apps-swift-with-cloud-sync-part-1-the-datastore/
[part-1-download]: https://developer.ibm.com/clouddataservices/2016/01/25/start-developing-ios-apps-swift-with-cloud-sync-part-1-the-datastore/#download-this-project
