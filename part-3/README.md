# Offline-First iOS Apps with Swift & Cloudant Sync; Part 3: User Interface

This walkthrough is a sequel to Apple's well-known iOS programming introduction, [Start Developing iOS Apps (Swift)][apple-doc]. Apple's introduction walks us through the process of building the UI, data, and logic of an example food tracker app, culiminating with a section on data persistence: storing the app data as files in the iOS device.

This series picks up where that document leaves off: syncing data between devices, through the cloud, with an offline-first design. You will achieve this using the free IBM Cloudant service, with open source tools.

This document is the third in the series, covering useful user interface features related to Cloudant Sync. You can also review the previous post in the series:

1. [Part 1: The Datastore][part-1].
1. [Part 2: Sync to the Cloud][part-2].

## Getting Started with FoodTracker

![The FoodTracker main screen](media/FoodTracker@2x.png "; figure")

This document assumes that you have completed [Part 2: The Datastore][part-2] of the series. If you have completed that walkthrough, you may continue with your FoodTracker project.

Alternatively, you can download the prepared project from the [Part 2 Code download][part-2-download] and begin there. Extract the zip file, `FoodTracker-Cloudant-Sync-2.zip`, browse into its folder with Finder, and double-click `FoodTracker.xcworkspace`. That will open the project in Xcode.

## Configure for Your Cloudant Account

If you downloaded the FoodTracker source code from the link above, then you must re-configure it to work with your own IBM Cloudant account. For a simple example like FoodTracker, these credentials are simply hard-coded in the source code. If you want to generate a new API key for your app, see the section in [Part 2, Prepare Cloudant for the Food Tracker App][part-2-prep].

1. Open `MealTableViewController.swift`
1. In `MealTableViewController.swift`, find the section, `MARK: Cloudant Settings`
1. Find the comment: `// NOTE: You must change these values for your own application.`
1. Modify the three values below that comment. For example:

  ``` swift
  // NOTE: You must change these values for your own application.
  let cloudantAccount = "my-name"
  let cloudantApiKey = "andougstonlyingeoledteat"
  let cloudantApiPassword = "995f34498cb918334c7f0b962b8e973ced13003d"
  ```

Checkpoint: **Run your app.** As always do not worry about compiler warnings from third-party, open source libraries.

In the console log, you should see messages indicating a successful pull replication. If everything is in order, proceed with these instructions. If you have a problem with compilation or replication, compare your code carefully to the code from [part 2][part-2].

If you download the prepared project, when you first open it with Xcode, you may see warnings about *CDTDatastore* and related names. This will go away on its own once Xcode has indexed the project. **Wait for Xcode to index** the project. Then, **run a build (Command-B)**. When that completes, you will know that everything is working correctly.

## Pull to Refresh

Pull-to-refresh is a great feature to give users visibility and control of the replication process. With pull-to-refresh, the user drags their finger downward, indicating their desire to retrieve updates from the cloud. This is a perfect place to trigger a pull replication!

Begin by enabling refreshing in the storyboard.

1. Open `Main.storyboard`
1. Look in the tree navigation panel, on the left. **Click the "Your Meals" view controller**, which has the yellow icon.

  ![Your meals view controller](media/refresh-15-view_controller@2x.png '; border')

  You will also see that the view controller is selected in the storyboard.

  ![Your meals view controller](media/refresh-20-view_controller@2x.png '; border')
  
1. In the Utilities (the rightmost panel in Xcode), be sure that you have selected the Attributes inspector. Visually scan down the attributes until you find the **View Table Controller** section.
1. In the **View Table Controller** section, **set the Refreshing attribute to Enabled**.

  ![Refreshing option in the "Your Meals" view controller](media/refresh-12-ui_screenshot_circle.png '; figure')

When complete, Xcode should look like this.

![Enabled refreshing in the "Your Meals" view controller](media/refresh-10-ui_screenshot@2x.png '; figure')

Next, implement the "refresh" function. It is very simple: just trigger pull replication.

1. In `MealTableViewController.swift`, find the section, `MARK: Cloudant Sync`
1. In the section `MARK: Cloudant Sync`, insert this function just above `cloudURL()`

  ``` swift
  func handleRefresh(refreshControl: UIRefreshControl) {
      print("Pull to refresh!")
      sync(.Pull)
  }
  ```

Of course, when the replication completes, the UI should reflect that. All you need to do is to stop the refresh control when a pull replication completes. (If the refresh control was not active, then nothing will happen, which is harmless.)

1. In `MealTableViewController.swift`, find the section, `MARK: Cloudant Sync`
1. Go to the function, `replicatorDidComplete(_:)`
1. In the code block for pull replications, append the code to end the refresh control. The `if` block in the middle of the function should now look like this:

  ``` swift
  if (replicator == replications[.Pull]) {
     if (replicator.changesProcessed > 0) {
         // Reload the meals, and refresh the UI.
         loadMealsFromDatastore()
         dispatch_async(dispatch_get_main_queue(), {
             self.tableView.reloadData()
         })
     }

     // End the refresh spinner, if necessary.
     self.refreshControl?.endRefreshing()
  }
  ```

The final step is to connect the UI refresh control to this code.

1. In `MealTableViewController.swift`, find the section, `MARK: Cloudant Settings`
1. Go to the function, `viewDidLoad()`
1. Add the following code, so that the beginning of the function looks like so:

  ``` swift
  super.viewDidLoad()
  
  // Activate the pull-to-refresh control.
  self.refreshControl = UIRefreshControl()
  self.refreshControl?.addTarget(self, action:
      #selector(MealTableViewController.handleRefresh(_:)),
      forControlEvents: UIControlEvents.ValueChanged)
  ```

Checkpoint: **Run your app.** As always do not worry about compiler warnings from third-party, open source libraries.

## Conclusion

Congratulations! Today's accomplishment is so delightful! Your users will appreciate these clear, tangible features: sync status spinners and pull-to-refresh. Although part 2 of this series lays the foundation for syncing, Food Tracker simply wasn't much fun to use without visual feedback and tactile control.

This concludes the major parts of this series. If you have followed along, then you have created an iOS app in Swift, using the local data store, `CDTDatastore`. You connected that datastore to IBM Cloudant, with bi-directional replication to and from Cloudant. Finally, you added user interface features to let users interact with these capabilities.

[END]: ------------------------------------------------

[apple-doc]: https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html
[code-download]: media/FoodTracker-Cloudant-Sync-3.zip
[part-1]: https://developer.ibm.com/clouddataservices/2016/01/25/start-developing-ios-apps-swift-with-cloud-sync-part-1-the-datastore/
[part-2]: http://developer.ibm.com/clouddataservices/?p=5451
[part-2-download]: https://developer.ibm.com/clouddataservices/2016/06/08/offline-first-ios-apps-part-2-cloud-sync/#download-this-project
[part-2-prep]: https://developer.ibm.com/clouddataservices/2016/06/08/offline-first-ios-apps-part-2-cloud-sync/#prepare-cloudant-for-the-foodtracker-app
