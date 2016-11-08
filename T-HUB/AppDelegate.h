//
//  AppDelegate.h
//  T-HUB
//
//  Created by Fangzhou Sun on 4/26/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DBManager.h"
//#import "LocationTracker.h"
#include "constants.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (retain, nonatomic) DBManager *dbManager;

@property (strong, nonatomic) NSMutableDictionary *reschedule_route_dictionary;

@property (nonatomic, assign) NSInteger selectedRouteNumber;

@property (nonatomic, assign) NSInteger calendar_added_schedule_timestamp;

// Location Tracker
//@property LocationTracker * locationTracker;
@property (nonatomic) NSTimer* locationUpdateTimer;

//
//@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
//@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
//@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
//
//- (void)saveContext;
//- (NSURL *)applicationDocumentsDirectory;

@end

