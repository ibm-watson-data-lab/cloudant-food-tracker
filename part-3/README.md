# Offline-First iOS Apps with Swift & Cloudant Sync; Part 3: User Interface

This walkthrough is a sequel to Apple's well-known iOS programming introduction, [Start Developing iOS Apps (Swift)][apple-doc]. Apple's introduction walks us through the process of building the UI, data, and logic of an example food tracker app, culiminating with a section on data persistence: storing the app data as files in the iOS device.

This series picks up where that document leaves off: syncing data between devices, through the cloud, with an offline-first design. You will achieve this using the free IBM Cloudant service, with open source tools.

This document is the third in the series, showing you how to sync the app data to Cloudant. You can also review the previous post in the series:

1. [Part 1: The Datastore][part-1].
1. [Part 2: Sync to the Cloud][part-2].

## Getting Started with FoodTracker

![The FoodTracker main screen](media/FoodTracker@2x.png "; figure")

This document assumes that you have completed [Part 2: The Datastore][part-2] of the series. If you have completed that walkthrough, you may continue with your FoodTracker project.

Alternatively, you can download the prepared project from the [Part 2 Code download][part-2-download] and begin there. Extract the zip file, `FoodTracker-Cloudant-Sync-2.zip`, browse into its folder with Finder, and double-click `FoodTracker.xcworkspace`. That will open the project in Xcode.

## Configure for Your Cloudant Account

If you downloaded the FoodTracker source code from the link above, then you must re-configure it to work with your own IBM Cloudant account. In FoodTracker, these credentials are simply hard-coded in the source code.

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

Checkpoint: **Run your app.** In the console log, you should see messages indicating a successful pull replication. If everything is in order, proceed with these instructions. If you have a problem with compilation or replication, compare your code carefully to the code from [part 2][part-2].

If you download the prepared project, when you first open it with Xcode, you may see warnings about *CDTDatastore* and related names. This will go away on its own once Xcode has indexed the project. **Wait for Xcode to index** the project. Then, **run a build (Command-B)**. When that completes, you will know that everything is working correctly.

## Next Steps: User Interface

## Conclusion

Congratulations! XXX Explain what has been accomplished XXX

[END]: ------------------------------------------------

[apple-doc]: https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html
[code-download]: media/FoodTracker-Cloudant-Sync-3.zip
[part-1]: https://developer.ibm.com/clouddataservices/2016/01/25/start-developing-ios-apps-swift-with-cloud-sync-part-1-the-datastore/
[part-2]: http://developer.ibm.com/clouddataservices/?p=5451
[part-2-download]: https://developer.ibm.com/clouddataservices/?p=5451&preview=true#download-this-project
