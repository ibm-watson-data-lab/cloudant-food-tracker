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

![The Cloudant home page](media/cloudant-01-home@2x.png '; border')

Click the red "Sign Up" button and fill out the sign-up form. Your *Username* will be in every URL you use. For example, the user *foodtracker* will be accessible at `https://foodtracker.cloudant.com`. This document uses that account for its examples. But you will choose your own unique username.

Complete the form, read the terms of service, and then click the red button, "I agree, sign me up".

![Signing up with Cloudant](media/cloudant-02-sign-up@2x.png '; border')

### The Cloudant Dashboard

When sign-up is complete, your browser will display the *Dashboard*.

![The Cloudant Dashboard home](media/dashboard-01-home@2x.png '; figure')

The Dashboard is the web interface to manage your data.

**Use the Dashboard to observe and verify FoodTracker's behavior.** This is a major advantage to using Cloudant: you have a simple and pleasant tool to help you do your job. In this walkthrough, you will frequently use the Dashboard in conjunction with the iOS Simulator.

### Prepare Cloudant for FoodTracker

Use the Dashboard to prepare the database for FoodTracker. To work correctly, FoodTracker will need a few things:

1. A *database*, to store data,
1. An *API key*, to authenticate, and
1. *Permission* to use the database

Begin by creating the database for FoodTracker. At the top of the Dashboard is the "Create Database" button. Click it, and a drop-down form will appear. Input the database name in "C-style" lower-case, underscore format: `food_tracker`.

![Create a Cloudant database](media/dashboard-02-create-db@2x.png '; border')

Welcome to *food_tracker*! You have a brand-new, clean database for FoodTracker to sync with.

![Database created](media/dashboard-02_1-db_created@2x.png '; figure=left')

In Cloudant, the database is foundational to an application: it is the "observable universe" of the application. In general, the meat of the Cloudant API applies at the database level. Access control, data validation, and queries all apply uniformly to a specific database and all data stored within.

Because databases are well-isolated from each other, *apps* are well-isolated. A single Cloudant account can bear several different mobile and web applications, simultaneously.

To review about names:

* Your *server* is named after your account. For example, the account for this document, `foodtracker`, is available at `https://foodtracker.cloudant.com/`.
* Your *database* is the storage place for FoodTracker data. For example, the database used in this document, `food_tracker`, is named after the iOS app. It is available at `https://foodtracker.cloudant.com/food_tracker`.
* Your **server name will be different** from this document
* Your **database name will be the same** as this document.

To see your database, use the Dashboard. From the "Databases" tab, click the link to *food_tracker*.

![The new meals database](media/dashboard-03-meals-db@2x.png '; border')

#### Create an API Key

Now, you must create an *API key*. The API key is a username and password pair. The FoodTracker app will use these credentials to access the cloud data.

**To create an API key**

1. Open the the *food_tracker* database in the Dashboard.
1. In the *food_tracker* database, click the "Permissions" link. ![The API Key manager](media/dashboard-03_1-api-key-page@2x.png '; border')
1. In the Permissions tab, click the "Generate API key" button and wait for Cloudant to generate a new key. ![Generating and API Key](media/dashboard-03_2-generating-key@2x.png '; border')
1. Cloudant will tell you when the key is ready. ![A new API key, ready for use](media/dashboard-03_3-new-api-key@2x.png '; border')

**Copy the API key and password now.** You will need to use these to connect from FoodTracker on iOS.

#### Grant API Permissions

The final step is to grant read, write, and replication access to your API key.

![Grant permissions to the new API key](media/dashboard-05-permissions@2x.png '; figure')

**To grant permissions to an API key**

1. In the Permissions tab, find the access control settings at the top of the page.
1. Find the row for your new API key, for example, *facringediftedgentlerrad*.
1. Check the columns for *Reader*, *Writer*, and *Replicator*.
1. Uncheck the column for *Admin*.

#### Confirm API Access

Now is the time to stop and confirm that everything is ready with your Cloudant service. The best way to do this on a Mac is to open Terminal and use `curl`. When you "curl" Cloudant, you will immediately see whether everything is working, and you can quickly determine what might be wrong. Begin by running the *Terminal* application.

The command below will authenticate to Cloudant and display the data. Notice that the username and password are inserted in the URL. The username is followed by `:`, then the password, then `@`, and then the usual hostname and path. When you paste this command into Terminal, **change the values to reflect your own server**.

    curl https://facringediftedgentlerrad:ee4c30dbd2f7457ccf6804f9536ad1a79f0ea9ad@foodtracker.cloudant.com/food_tracker/_all_docs

![Confirm API access using cURL](media/confirm-api-access@2x.png '; border')

If you **see an empty listing of documents**, you have completed everything.

Good job! Your Cloudant cloud is all prepared to be a central storage of FoodTracker data.

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
