//
//  CoreDataHelper.h
//  CoreDataExample1
//
//  Created by Training on 21.05.14.
//  https://www.youtube.com/watch?v=H2BxGEGyeLg
//  Copyright (c) 2014 Training. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataHelper : NSObject

+(NSString*)directoryForDatabaseFilename;
+(NSString*)databaseFilename;

+(NSManagedObjectContext*)managedObjectContext;

+(id)insertManagedObjectOfClass:(Class)aClass inManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

+(BOOL)saveManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

+(NSArray*)fetchEntitiesForClass:(Class)aClass withPredicate:(NSPredicate*)predicate inManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
