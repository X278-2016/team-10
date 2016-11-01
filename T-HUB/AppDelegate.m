//
//  AppDelegate.m
//  T-HUB
//
//  Created by Fangzhou Sun on 4/26/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import "UserConsentViewController.h"
#import "AppData.h"
#import "Reachability.h"


@interface AppDelegate () {
    Reachability *reachability;
    Boolean flag_wasNoConnection;
}

@end

@implementation AppDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /*
     NSManagedObjectContext* context = [CoreDataHelper managedObjectContext];
     
     UserConsent* userConsent = [CoreDataHelper insertManagedObjectOfClass:[UserConsent class] inManagedObjectContext:context];
     
     userConsent.status = @"NO";
     
     [CoreDataHelper saveManagedObjectContext:context];
     
     NSArray* items = [CoreDataHelper fetchEntitiesForClass:[UserConsent class] withPredicate:nil inManagedObjectContext:context];
     
     for (UserConsent* userConsent in items){
     NSLog(@"UserConsent: %@", userConsent.status);
     //        [context deleteObject:userConsent];
     }
     userConsent = [CoreDataHelper insertManagedObjectOfClass:[UserConsent class] inManagedObjectContext:context];
     
     userConsent.status = @"VARY";
     
     [CoreDataHelper saveManagedObjectContext:context];
     items = [CoreDataHelper fetchEntitiesForClass:[UserConsent class] withPredicate:nil inManagedObjectContext:context];
     NSLog(@"items.count: %lu",(unsigned long)items.count);
     
     
     NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
     NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"UserConsent"  inManagedObjectContext: context];
     [fetch setEntity:entityDescription];
     [fetch setPredicate:[NSPredicate predicateWithFormat:@"(ANY status contains[cd] %@)",@"NO"]];
     NSError * error = nil;
     NSArray *fetchedObjects = [context executeFetchRequest:fetch error:&error];
     NSLog(@"fetchedObjects.count: %lu",(unsigned long)fetchedObjects.count);
     */
    // Override point for customization after application launch.
    
    [self switchRootViewController];
    
    // Add Google API Key
    [GMSServices provideAPIKey:@"AIzaSyActwr0gj8ndXJt6z0LAQFxWggTPBjMzCA"];
    
//    [self checkIfBackgroundAppRefreshIsEnabled];
    
    // Initial database
    self.dbManager = [[DBManager alloc] initWithDatabaseFilename:@"Nashville_GTFS.sqlite3"];
    
    
    self.reschedule_route_dictionary = nil;
    self.selectedRouteNumber = 0;
    
    UIUserNotificationType types = UIUserNotificationTypeBadge |
    UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *mySettings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"AlertTime"]==nil) {
        [defaults setObject:[NSNumber numberWithFloat:30] forKey:@"AlertTime"];
        [defaults synchronize];
    }
    if ([defaults objectForKey:@"thubTimeBool"]==nil) {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"thubTimeBool"];
        [defaults synchronize];
    }
    if ([defaults objectForKey:@"demoMode"]==nil) {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"demoMode"];
        [defaults synchronize];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:kReachabilityChangedNotification object:nil];
    
    reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
//    NSLog(@"TMP:::::::%@", [self.dbManager getDepartureAndArrivalTimeByTripID:@"116305"]);
    //[Fabric with:@[CrashlyticsKit]];
    
    
//    NSArray *testArray = [self.dbManager loadDataFromDB:@"SELECT start_st.trip_id                      FROM stop_times start_st                      LEFT JOIN stops start_s ON start_st.stop_id = start_s.stop_id                      WHERE start_st.departure_time='20:43:45' AND start_s.stop_name='AMERICAN STATION OUTBOUND' "];
    
//    NSArray *testArray = [self.dbManager loadDataFromDB:@"SELECT start_st.trip_id                      FROM stop_times start_st                      LEFT JOIN stops start_s ON start_st.stop_id = start_s.stop_id                      WHERE start_st.stop_id='CXOAMERI'"];
//    
//    NSLog(@"TESTTT: %@", testArray);
//        [NSThread sleepForTimeInterval:10];
    return YES;
}

- (void)networkChanged:(NSNotification *)notification
{
    
    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    
    if(remoteHostStatus == NotReachable) {
        flag_wasNoConnection = YES;
        NSLog(@"not reachable");
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@""
                                      message:@"No Internet connection."
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Got it"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        //Handel your yes please button action here
                                        [alert dismissViewControllerAnimated:YES completion:nil];
                                        
                                    }];
        
        [alert addAction:yesButton];
        
        [((UITabBarController*)self.window.rootViewController).selectedViewController presentViewController:alert animated:YES completion:nil];
        
    } else if (remoteHostStatus == ReachableViaWiFi || remoteHostStatus == ReachableViaWWAN) {
        NSLog(@"wifi or carrier");
        if (!flag_wasNoConnection)
            return;
        flag_wasNoConnection = NO;
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:@""
                                      message:@"Connected to Internet."
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Got it"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        //Handel your yes please button action here
                                        [alert dismissViewControllerAnimated:YES completion:nil];
                                        
                                    }];
        
        [alert addAction:yesButton];
        
        [((UITabBarController*)self.window.rootViewController).selectedViewController presentViewController:alert animated:YES completion:nil];
        
    }
}

- (void)switchRootViewController {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Check if consent accepted.
    NSManagedObjectContext *objectContext = [CoreDataHelper managedObjectContext];
    //    AppData* appData = [CoreDataHelper insertManagedObjectOfClass:[AppData class] inManagedObjectContext:objectContext];
    NSArray *items = [CoreDataHelper fetchEntitiesForClass:[AppData class] withPredicate:nil inManagedObjectContext:objectContext];
    if ([items count]>0) {
        AppData* tmp = [items lastObject];
        //        appData.userConsent = tmp.userConsent;
        //        for (AppData * appData in items)
        //            [objectContext deleteObject:appData];
        if ([tmp.userConsent isEqualToString:@"YES"]) {
            UITabBarController *vc = (UITabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"MainTabBarController"];
            self.window.rootViewController = vc;
            [self.window makeKeyAndVisible];
            return;
        }
    }
    UIViewController *vc = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:@"UserConsentViewController"];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
}

/*
- (void)checkIfBackgroundAppRefreshIsEnabled {
    UIAlertView * alert;
    
    //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
    if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The app doesn't work without the Background App Refresh enabled. To turn it on, go to Settings > General > Background App Refresh"
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The functions of this app are limited because the Background App Refresh is disable."
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    } else{
        
        self.locationTracker = [[LocationTracker alloc]init];
        [self.locationTracker startLocationTracking];
        
        //        NSTimeInterval time = 10.0;
        //        self.locationUpdateTimer =
        //        [NSTimer scheduledTimerWithTimeInterval:time
        //                                         target:self
        //                                       selector:@selector(updateLocation)
        //                                       userInfo:nil
        //                                        repeats:YES];
    }
}
 */

//-(void)updateLocation {
//
//    if (myLastLocation.latitude == self.locationTracker.myLastLocation.latitude && myLastLocation.longitude == self.locationTracker.myLastLocation.longitude) {
//
//    } else {
//        myLastLocation.latitude = self.locationTracker.myLastLocation.latitude;
//        myLastLocation.longitude = self.locationTracker.myLastLocation.longitude;
//        [self.locationTracker updateLocationToServer];
//    }
//}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/*
 #pragma mark - Core Data stack
 
 @synthesize managedObjectContext = _managedObjectContext;
 @synthesize managedObjectModel = _managedObjectModel;
 @synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
 
 - (NSURL *)applicationDocumentsDirectory {
 // The directory the application uses to store the Core Data store file. This code uses a directory named "com.fangzhou.JustForTest" in the application's documents directory.
 return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
 }
 
 - (NSManagedObjectModel *)managedObjectModel {
 // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
 if (_managedObjectModel != nil) {
 return _managedObjectModel;
 }
 NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Device" withExtension:@"momd"];
 _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
 return _managedObjectModel;
 }
 
 - (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
 // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
 if (_persistentStoreCoordinator != nil) {
 return _persistentStoreCoordinator;
 }
 
 // Create the coordinator and store
 
 _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
 NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"T-HUB.sqlite"];
 NSError *error = nil;
 NSString *failureReason = @"There was an error creating or loading the application's saved data.";
 if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
 // Report any error we got.
 NSMutableDictionary *dict = [NSMutableDictionary dictionary];
 dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
 dict[NSLocalizedFailureReasonErrorKey] = failureReason;
 dict[NSUnderlyingErrorKey] = error;
 error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
 // Replace this with code to handle the error appropriately.
 // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
 NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
 abort();
 }
 
 return _persistentStoreCoordinator;
 }
 
 
 - (NSManagedObjectContext *)managedObjectContext {
 // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
 if (_managedObjectContext != nil) {
 return _managedObjectContext;
 }
 
 NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
 if (!coordinator) {
 return nil;
 }
 _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
 [_managedObjectContext setPersistentStoreCoordinator:coordinator];
 return _managedObjectContext;
 }
 
 #pragma mark - Core Data Saving support
 
 - (void)saveContext {
 NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
 if (managedObjectContext != nil) {
 NSError *error = nil;
 if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
 // Replace this implementation with code to handle the error appropriately.
 // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
 NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
 abort();
 }
 }
 }
 */


@end
