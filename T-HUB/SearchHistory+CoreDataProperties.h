//
//  SearchHistory+CoreDataProperties.h
//  T-HUB
//
//  Created by Fangzhou Sun on 12/6/15.
//  Copyright © 2015 Fangzhou Sun. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "SearchHistory.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchHistory (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *address;
@property (nullable, nonatomic, retain) NSNumber *timestamp;

@end

NS_ASSUME_NONNULL_END
