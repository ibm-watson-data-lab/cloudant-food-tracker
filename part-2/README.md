# Start Developing iOS Apps (Swift) with Cloud Sync; Part 2: Sync to Cloudant

This walkthrough is a sequel to Apple's well-known iOS programming introduction, [Start Developing iOS Apps (Swift)][apple-doc]. Apple's introduction walks us through the process of building the UI, data, and logic of an example food tracker app, culiminating with a section on data persistence: storing the app data as files in the iOS device.

This series picks up where that document leaves off: syncing data between devices, through the cloud, with an offline-first design. You will achieve this using open source tools and the IBM Cloudant service.

This document is the second in the series, showing you how to sync the app data to Cloudant. You can also review the previous post in the series, [Part 1: The Datastore][part-1].

## Outline

**This will be removed before publishing**

* Getting Started with FoodTracker
* Getting Started with IBM Cloudant
  * Create a Free IBM Cloudant Account
  * Create a database for meals
  * Give FoodTracker access to a database
    * Generate an API key
    * Set permissions
    * Confirm with curl -I, confirm status code, confirm body
* How to Start Over
  * How to delete iOS Simulator data
  * How to delete Cloudant data
* Push replication
  * The sync code
  * Set the user-agent
    * figure out how to explain why besides ("so we can track adoption")
    * Maybe because you can use this with CouchDB and you'll want to track it there.
  * Sync when samples are created
  * Confirm in dashboard: run the app and look for changes
  * Sync when the user makes a change
  * Confirm in dashboard
* Pull replication
  * New code: update the sync to support pull
  * Activate pull sync when the app starts
  * Confirm
    * Change a rating in the dashboard
    * Start the app
    * Note the star change
* Next steps: UI integration
  * Visual feedback of pushing
  * Pull to refresh
  * Be vague since I'm less clear what the scope is

## Getting Started with FoodTracker

![The FoodTracker main screen](media/FoodTracker@2x.png "; figure")

This document assumes that you have completed [Part 1: The Datastore][part-1] of the series. If you have completed that walkthrough, you may continue with your FoodTracker project.

Alternatively, you can download the prepared project from the [Part 1 Code download][part-1-download] and begin there. Extract the zip file, `FoodTracker-Cloudant-Sync-1.zip`, browse into its folder with Finder, and double-click `FoodTracker.xcworkspace`. That will open the project in Xcode. Run the app (Command-R) and confirm that it works correctly. If everything is in order, proceed with these instructions.

## Getting Started with Cloudant

In this section, you will create a free IBM Cloudant account, with which to support FoodTracker. If you already have an account, then you can use it. Just skip down and [prepare the system for FoodTracker][prepare-service].

### Create a Free IBM Cloudant Account

Getting started with IBM Cloudant is free and easy. Begin by signing up on [Cloudant.com][cloudant-home].

![The Cloudant home page](media/cloudant-01-home@2x.png)

Click the red "Sign Up" button and fill out the sign-up form. Your **Username** will be the prefix of your database's URL. For example, the user "foodtracker" will be accessible at `https://foodtracker.cloudant.com`, used in the examples in this document. But you must choose your own unique username.

Complete the form, read the terms of service, and then click the red button, "I agree, sign me up".

![Signing up with Cloudant](media/cloudant-02-sign-up@2x.png)

### The Cloudant Dashboard

When sign-up is complete, your browser will display the **Dashboard**.

![The Cloudant Dashboard home](media/dashboard-01-home@2x.png '; figure')

The Dashboard is a a web application for managing your IBM Cloudant data. From the Dashboard, you can manage your database and work with data. You will use this dashboard to explore and experiment with FoodTracker's data.

**Use the Dashboard to observe and verify the iOS app's behavior.** This is a major advantage when using Cloudant: you have a simple and pleasant tool to help you do your job. In this walkthrough, you will often use the Dashboard in conjunction with the iOS Simulator.

### Prepare Cloudant for FoodTracker

Use the Dashboard to prepare the database for FoodTracker. To work correctly, FoodTracker will need a few things:

1. A *database*, to store data
1. An *API key*, to authenticate
1. *Permission* to use the database

First, create a database in the dashboard.

![Create a Cloudant database](media/dashboard-02-create-db@2x.png)

![The new meals database](media/dashboard-03-meals-db@2x.png)

![Create an API key](media/dashboard-04-api-key@2x.png)

![Grant permissions to the new API key](media/dashboard-05-permissions@2x.png)

![The meals database is ready](media/dashboard-06-meals-db-ready@2x.png)

![Confirm API access using cURL](media/confirm-api-access@2x.png)

## Conclusion

Congratulations! XXX Explain what has been accomplished

XXX Tease the next section

## Download This Project

To see the completed sample project for this lesson, download the file and view it in Xcode.

[Download File][code-download]

## XXX Unresolved To-Dos

Is there any good or official documentation about using the dashboard?

Set user-agent

Crop the stupid drop shadow on the screenshots

Do we want to make a design doc for the shared project where people can create images? We could probably reuse that work in a future chapter about security

[END]: ------------------------------------------------

[apple-doc]: https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html
[cloudant-home]: https://cloudant.com/
[code-download]: media/FoodTracker-Cloudant-Sync-2.zip
[part-1]: https://developer.ibm.com/clouddataservices/2016/01/25/start-developing-ios-apps-swift-with-cloud-sync-part-1-the-datastore/
[part-1-download]: https://developer.ibm.com/clouddataservices/2016/01/25/start-developing-ios-apps-swift-with-cloud-sync-part-1-the-datastore/#download-this-project
[prepare-service]: #prepare-cloudant-for-foodtracker
