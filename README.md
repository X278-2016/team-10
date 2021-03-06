# Smart Cities Transit-Hub iOS App (Team 10)
The original app is written in Objective-C by [fzsun316](mailto:fzsun316@gmail.com) and has been released on [iOS App Store](https://itunes.apple.com/us/app/t-hub/id1022519348?mt=8).

## Key Components

* Constants ([Constants](https://github.com/X278-2016/team-10/blob/master/T-HUB/constants.h)): This file defines all the URLs.
* User Consent View ([UserConsentViewController](https://github.com/X278-2016/team-10/blob/master/T-HUB/UserConsentViewController.h): User needs to accept the user consent to use the app
* Tab Bar View ([TabBarController](https://github.com/X278-2016/team-10/blob/master/T-HUB/TabBarController.h)):  This controller defines the tab bar items
* Trip Planner ([TripPlanner2ViewController](https://github.com/X278-2016/team-10/blob/master/T-HUB/TripPlanner2ViewController.h)): Users use this view to plan a trip to their destinations.
* Real-time Navigation ([RealtimeViewController](https://github.com/X278-2016/team-10/blob/master/T-HUB/RealtimeViewController.h)): Step-by-step navigation will be provided by this view.
* Suggested Route View ([SuggestedRoutesViewController](https://github.com/X278-2016/team-10/blob/master/T-HUB/SuggestedRoutesViewController.h)): This view provides the suggested transit routes to users after they tap the "Plan Your Trip" button in trip planner.
* Route Detail View ([SuggestedRoutesViewController](https://github.com/X278-2016/team-10/blob/master/T-HUB/SuggestedRoutesViewController.h)): Users can check the details of suggested routes here.
* Calendar ([CalendarViewController](https://github.com/X278-2016/team-10/blob/master/T-HUB/CalendarViewController.h)): Users use this view to manage the scheduled trips in the future.
* Route Query View ([RouteQueryViewController](https://github.com/X278-2016/team-10/blob/master/T-HUB/RouteQueryViewController.h)): Users can check the real-time bus locations and estimated arrival time for different routes.
* Summary View ([SummaryTableViewController](https://github.com/X278-2016/team-10/blob/master/T-HUB/SummaryTableViewController.h)): Users can check the summary data here
* Setting View ([SettingTableViewController](https://github.com/X278-2016/team-10/blob/master/T-HUB/SettingViewController.h)): Users can change the default settings here

## Improvement Ideas

The existing app is functioning, but we see many areas for improvement.  Our ideas for improvement as of 10/27 are as follows:
- Creating a real-time feature that shows multiple buses near you at a time
- Revamping the calendar feature's user interface to only show you the days when you have a trip planned, makes for less scrolling through and easy access to trips
- Share feature that allows your friends to see the trip you've planned if they would like to join
- Automatic recalculation of new route if you miss your bus
- Preferred trip type: Shortest trip, Soonest Departure, Soonest Arrival

##Relevant Links

* [TRANSIT-HUB](http://thub.isis.vanderbilt.edu) - Info and goal of current app
* [Transit](https://transitapp.com) - Smart Transit app similar concept
* [Nashville MTA Real-Time](http://ride.nashvillemta.org) - Nashville MTA's real-time bus tracker and trip planner


## Project Timeline

*Source Code Arrived Nov 8. Timeline has been updated accordingly.*


* Thu, Nov 10 - Meet with Professor White, discuss plan form this point forward

* Tue, Nov 15 - Code read through, understand app flow, be prepared with questions for Fangzhou Sun on Tuesday

* Thu, Nov 17 - Meet with Prof. White

* Nov 29 - Sprint: Implementation of nearby buses and share or updated calendar features

* Tue, Nov 29 - Sprint

* Thu, Dec 1 - Meet with Prof. White

* Dec 6 - Sprint 2

* Tue, Dec 6 - Sprint 3: Finalize features and demo

* Thu, Dec 8 - Final Presentation

## Team members

+ [Ellis Brown](mailto:ellis.l.brown@vanderbilt.edu) - Developer
+ [Caelan Collins](mailto:caelan.p.collins@vanderbilt.edu) - Developer
+ [Raven Delk](mailto:raven.delk@vanderbilt.edu) - Project Manager
