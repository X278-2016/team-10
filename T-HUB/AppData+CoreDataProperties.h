//
//  AppData+CoreDataProperties.h
//  T-HUB
//
//  Created by Fangzhou Sun on 11/30/15.
//  Copyright © 2015 Fangzhou Sun. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "AppData.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppData (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *userConsent;

@end

NS_ASSUME_NONNULL_END
