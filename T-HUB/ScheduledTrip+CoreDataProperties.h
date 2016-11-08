//
//  ScheduledTrip+CoreDataProperties.h
//  T-HUB
//
//  Created by Fangzhou Sun on 12/10/15.
//  Copyright © 2015 Fangzhou Sun. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ScheduledTrip.h"

NS_ASSUME_NONNULL_BEGIN

@interface ScheduledTrip (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *arrivalLat;
@property (nullable, nonatomic, retain) NSString *arrivalLng;
@property (nullable, nonatomic, retain) NSString *arrivalText;
@property (nullable, nonatomic, retain) NSNumber *arrivalTime;
@property (nullable, nonatomic, retain) NSNumber *checkpoint;
@property (nullable, nonatomic, retain) NSString *departureLat;
@property (nullable, nonatomic, retain) NSString *departureLng;
@property (nullable, nonatomic, retain) NSString *departureText;
@property (nullable, nonatomic, retain) NSNumber *departureTime;
@property (nullable, nonatomic, retain) NSString *fromAddress;
@property (nullable, nonatomic, retain) NSString *googleTripDic;
@property (nullable, nonatomic, retain) NSNumber *isRecurring;
@property (nullable, nonatomic, retain) NSString *searchID;
@property (nullable, nonatomic, retain) NSString *toAddress;
@property (nullable, nonatomic, retain) NSString *uuid;
@property (nullable, nonatomic, retain) NSNumber *scheduledDepartureTime;

@end

NS_ASSUME_NONNULL_END
