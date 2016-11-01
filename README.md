# Transit-Hub iOS App

The app is written in Objective-C and has been released on [iOS App Store](https://itunes.apple.com/us/app/t-hub/id1022519348?mt=8). If you have any question, you can find me [here](mailto:fzsun316@gmail.com)

## Key Components

* Constants ([Constants](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/constants.h)): This file defines all the URLs.
* User Consent View ([UserConsentViewController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/UserConsentViewController.h)): User needs to accept the user consent to use the app
* Tab Bar View ([TabBarController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/TabBarController.h)):  This controller defines the tab bar items
* Trip Planner ([TripPlanner2ViewController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/TripPlanner2ViewController.h)): Users use this view to plan a trip to their destinations.
* Real-time Navigation ([RealtimeViewController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/RealtimeViewController.h)): Step-by-step navigation will be provided by this view.
* Suggested Route View ([SuggestedRoutesViewController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/SuggestedRoutesViewController.h)): This view provides the suggested transit routes to users after they tap the "Plan Your Trip" button in trip planner.
* Route Detail View ([SuggestedRoutesViewController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/SuggestedRoutesViewController.h)): Users can check the details of suggested routes here.
* Calendar ([CalendarViewController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/CalendarViewController.h)): Users use this view to manage the scheduled trips in the future.
* Route Query View ([RouteQueryViewController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/RouteQueryViewController.h)): Users can check the real-time bus locations and estimated arrival time for differenct routes.
* Summary View ([SummaryTableViewController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/SummaryTableViewController.h)): Users can check the summary data here
* Setting View ([SettingTableViewController](https://github.com/visor-vu/thub-ios-app/blob/master/T-HUB/SettingTableViewController.h)): Users can change the default settings here
