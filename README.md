# Start Developing iOS Apps (Swift) - With Cloud Data Sync

This walkthrough is a "sequel" to Apple's well-known iOS programming introduction, [Start Developing iOS Apps (Swift)][apple-doc]. Apple's introduction walks us through the process of building the UI, data, and logic of an example food tracker app, culiminating with a section on data persistence: storing the app data as files in the iOS device.

This document picks up where that document leaves off: syncing data between devices, through the cloud, with an offline-first design. We will achieve this using open source tools and the IBM Cloudant service.

## About the Lessons

These lessons assume that you have completed the [FoodTracker app][apple-doc] from Apple's walkthrough. We begin with the completed sample project from the final lesson: [Persist Data][apple-doc-download].

<img src="https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/Art/8_sim_navbar_2x.png" alt="Image of FoodTracker app" height="559" width="320">

[apple-doc]: https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html
[apple-doc-download]: https://developer.apple.com/library/prerelease/ios/referencelibrary/GettingStarted/DevelopiOSAppsSwift/Lesson10.html#//apple_ref/doc/uid/TP40015214-CH14-SW3
