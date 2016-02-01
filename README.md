# iOS Swift Walkthrough

This is the workshop where we work on the Swift iOS with Cloudant Sync documents. Post to wordpress using [GFM-WordPress][gfm-wordpress].

1. Part 1: The Datastore
  * [Markdown draft](part-1/README.md)
  * [Blog post](https://developer.ibm.com/clouddataservices/2016/01/25/start-developing-ios-apps-swift-with-cloud-sync-part-1-the-datastore/)
2. Part 2: Cloud Sync
  * [Markdown draft](part-2/README.md)
  * [Blog post](https://developer.ibm.com/clouddataservices/?p=5451&preview=true)

## Contributing

How to create or update the sample download. (Maybe we could move this to Git. For now the code in Git is more of a scratch area where I try things out.before I write it up.)

1. Begin with the previous lesson's download (or the Apple download if working on lesson 1)
1. Make a random place for the project (slightly superstitious but it can't hurt)

  ```
  foodtracker_work="$HOME/Desktop/FT-$RANDOM"
  mkdir "$foodtracker_work"
  cd "$foodtracker_work"
  ```
1. Extract the zip file e.g. `unzip ~/Downloads/FoodTracker-Cloudant-Sync-1.zip`
1. Rename the directory to the current lesson (i.e. increment the "1" to a "2", etc.)
1. Open in Xcode: `open FoodTracker-Cloudant-Sync-1/FoodTracker\ -\ Cloudant\ Datastore/FoodTracker.xcworkspace`
1. Follow the lesson instructions scrupulously
1. When done, clean the build in Xcode: Product -> Clean (or Shift-Command-K)
1. Zip it up, e.g. `zip -r FoodTracker-Cloudant-Sync-2.zip FoodTracker-Cloudant-Sync-2/`
1. Commit the zip file to the documentation, e.g. `cloudant-food-tracker/part-2/media/` and link it from the README.


[gfm-wordpress]: https://github.com/jhs/gfm-wordpress
