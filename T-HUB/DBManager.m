//
//  DBManager.m
//  GCTC
//
//  Created by Fangzhou Sun on 3/9/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "DBManager.h"
#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>


@interface DBManager()

@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSString *databaseFilename;

-(void)copyDatabaseIntoDocumentsDirectory;
@property (nonatomic, strong) NSMutableArray *arrResults;
-(void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable;

@end

@implementation DBManager

-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename{
    self = [super init];
    if (self) {
        // Set the documents directory path to the documentsDirectory property.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentsDirectory = [paths objectAtIndex:0];
        
        // Keep the database filename.
        self.databaseFilename = dbFilename;
        
        // Copy the database file into the documents directory if necessary.
        [self copyDatabaseIntoDocumentsDirectory];
    }
    return self;
}

- (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *) filePathString
{
    NSLog(@"%@", filePathString);
    NSURL* URL= [NSURL fileURLWithPath: filePathString];
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

-(void)copyDatabaseIntoDocumentsDirectory{
    
    // Check if the database file exists in the documents directory.
    NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: destinationPath]) {
        NSLog(@"dfasdfasdf");
        [self addSkipBackupAttributeToItemAtPath:destinationPath];
//                [[NSFileManager defaultManager] removeItemAtPath: destinationPath error:nil];
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        NSLog(@"erqweeqwr");
    // The database file does not exist in the documents directory, so copy it from the main bundle now.
    NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseFilename];
    NSError *error;
    
    //    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:sourcePath];
    
    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:&error];
    
    [self addSkipBackupAttributeToItemAtPath:destinationPath];
    
    // Check if any error occurred during copying and display it.
    if (error != nil) {
        NSLog(@"copyItemAtPath:%@", [error localizedDescription]);
    }
    }
}

-(void)runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable{
    // Create a sqlite object.
    sqlite3 *sqlite3Database;
    
    // Set the database file path.
    NSString *databasePath = [self.documentsDirectory stringByAppendingPathComponent:self.databaseFilename];
    
    // Initialize the results array.
    if (self.arrResults != nil) {
        [self.arrResults removeAllObjects];
        self.arrResults = nil;
    }
    self.arrResults = [[NSMutableArray alloc] init];
    
    // Initialize the column names array.
    if (self.arrColumnNames != nil) {
        [self.arrColumnNames removeAllObjects];
        self.arrColumnNames = nil;
    }
    self.arrColumnNames = [[NSMutableArray alloc] init];
    
    
    // Open the database.
    BOOL openDatabaseResult = sqlite3_open([databasePath UTF8String], &sqlite3Database);
    if(openDatabaseResult == SQLITE_OK) {
        // Declare a sqlite3_stmt object in which will be stored the query after having been compiled into a SQLite statement.
        sqlite3_stmt *compiledStatement;
        
        // Load all data from database to memory.
        BOOL prepareStatementResult = sqlite3_prepare_v2(sqlite3Database, query, -1, &compiledStatement, NULL);
        if(prepareStatementResult == SQLITE_OK) {
            // Check if the query is non-executable.
            if (!queryExecutable){
                // In this case data must be loaded from the database.
                
                // Declare an array to keep the data for each fetched row.
                NSMutableArray *arrDataRow;
                
                // Loop through the results and add them to the results array row by row.
                while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
                    // Initialize the mutable array that will contain the data of a fetched row.
                    arrDataRow = [[NSMutableArray alloc] init];
                    
                    // Get the total number of columns.
                    int totalColumns = sqlite3_column_count(compiledStatement);
                    
                    // Go through all columns and fetch each column data.
                    for (int i=0; i<totalColumns; i++){
                        // Convert the column data to text (characters).
                        char *dbDataAsChars = (char *)sqlite3_column_text(compiledStatement, i);
                        
                        // If there are contents in the currenct column (field) then add them to the current row array.
                        if (dbDataAsChars != NULL) {
                            // Convert the characters to string.
                            [arrDataRow addObject:[NSString  stringWithUTF8String:dbDataAsChars]];
                        }
                        
                        // Keep the current column name.
                        if (self.arrColumnNames.count != totalColumns) {
                            dbDataAsChars = (char *)sqlite3_column_name(compiledStatement, i);
                            [self.arrColumnNames addObject:[NSString stringWithUTF8String:dbDataAsChars]];
                        }
                    }
                    
                    // Store each fetched data row in the results array, but first check if there is actually data.
                    if (arrDataRow.count > 0) {
                        [self.arrResults addObject:arrDataRow];
                    }
                }
            }
            else {
                // This is the case of an executable query (insert, update, ...).
                
                // Execute the query.
                int executeQueryResults = sqlite3_step(compiledStatement);
                
                if (executeQueryResults == SQLITE_DONE) {
                    // Keep the affected rows.
                    self.affectedRows = sqlite3_changes(sqlite3Database);
                    
                    // Keep the last inserted row ID.
                    self.lastInsertedRowID = sqlite3_last_insert_rowid(sqlite3Database);
                }
                else {
                    // If could not execute the query show the error message on the debugger.
                    NSLog(@"DB Error: %s", sqlite3_errmsg(sqlite3Database));
                }
            }
        }
        else {
            // In the database cannot be opened then show the error message on the debugger.
            NSLog(@"%s", sqlite3_errmsg(sqlite3Database));
        }
        
        // Release the compiled statement from memory.
        sqlite3_finalize(compiledStatement);
        
    }
    
    // Close the database.
    sqlite3_close(sqlite3Database);
}

-(NSArray *)loadDataFromDB:(NSString *)query{
    // Run the query and indicate that is not executable.
    // The query string is converted to a char* object.
    [self runQuery:[query UTF8String] isQueryExecutable:NO];
    
    // Returned the loaded results.
    return (NSArray *)self.arrResults;
}

-(void)executeQuery:(NSString *)query{
    // Run the query and indicate that is executable.
    [self runQuery:[query UTF8String] isQueryExecutable:YES];
}

-(NSString *)getRouteID:(NSString *)route_long_name route_short_name:(NSString *)route_short_name {
    NSLog(@"getRouteID");
    NSString *query;
    
    if (route_long_name)
        query = [NSString stringWithFormat:@"SELECT T1.route_id \
                 FROM routes AS T1 \
                 WHERE T1.route_long_name='%@'",route_long_name];
    else
        query = [NSString stringWithFormat:@"SELECT T1.route_id \
                 FROM routes AS T1 \
                 WHERE T1.route_short_name='%@'",route_short_name];
    
    NSArray *results = [self loadDataFromDB:query];
    NSLog(@"%@",results);
    
    if (results && [results count]>0 && (results[0])[0]) {
        return [NSString stringWithFormat:@"%@",(results[0])[0] ];
    } else
        return nil;
}

- (NSString *)getRouteIDFromRouteDic:(NSMutableDictionary *)route_dic step_index:(int)step_index {
    // Parse the route dictionary
    NSMutableDictionary *leg_array = [[route_dic objectForKey:@"legs"] objectAtIndex:0];
    
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    
    if([steps_array count]>step_index) {
        NSMutableDictionary *one_step = [steps_array objectAtIndex:step_index];
        
        if ([[one_step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            // Get route id
            NSString *route_short_name = [[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"short_name"];
            NSString *route_long_name = [[[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"name"] uppercaseString];
            
            NSString *route_id = [self getRouteID:route_long_name route_short_name:route_short_name];
            return route_id;
        }
    }
    return nil;
}

-(NSArray *)getTripID:(NSString *)route_id departure_stop_name:(NSString *)departure_stop_name departure_stop_lat:(NSString *)departure_stop_lat departure_stop_lon:(NSString *)departure_stop_lon arrival_stop_name:(NSString *)arrival_stop_name arrival_stop_lat:(NSString *)arrival_stop_lat arrival_stop_lon:(NSString *)arrival_stop_lon departure_time:(NSString *)departure_time arrival_time:(NSString *)arrival_time {
    NSLog(@"q1");
    NSString *query = [NSString stringWithFormat:@"SELECT trips.trip_id FROM trips JOIN stop_times ON trips.route_id = '%@' AND trips.trip_id = stop_times.trip_id AND stop_times.arrival_time='%@' JOIN stops ON stops.stop_id = stop_times.stop_id AND stops.stop_lat = '%@' AND stops.stop_lon = '%@' AND stops.stop_name = '%@'", route_id, arrival_time, arrival_stop_lat, arrival_stop_lon, arrival_stop_name];
    
    NSArray *results = [self loadDataFromDB:query];
    
    NSLog(@"q1 query%@", query);
    NSLog(@"%@",results);
    
    NSMutableArray *trip_array = [[NSMutableArray alloc] initWithCapacity:5];
    NSEnumerator *enmueratorsteps_array = [results objectEnumerator];
    NSMutableArray *step;
    while (step = [enmueratorsteps_array nextObject]) {
        [trip_array addObject: [step objectAtIndex:0]];
    }
    
    NSLog(@"q2");
    NSString *query2 = [NSString stringWithFormat:@"SELECT trips.trip_id FROM trips JOIN stop_times ON trips.route_id = '%@' AND trips.trip_id = stop_times.trip_id AND stop_times.arrival_time='%@' JOIN stops ON stops.stop_id = stop_times.stop_id AND stops.stop_lat = '%@' AND stops.stop_lon = '%@' AND stops.stop_name = '%@'", route_id, departure_time, departure_stop_lat, departure_stop_lon, departure_stop_name];
    
    
    NSArray *results2 = [self loadDataFromDB:query2];
    NSLog(@"q2 query%@", query2);
    NSLog(@"%@",results2);
    NSMutableArray *trip_array2 = [[NSMutableArray alloc] initWithCapacity:5];
    NSEnumerator *enmueratorsteps_array2 = [results2 objectEnumerator];
    NSMutableArray *step2;
    while (step2 = [enmueratorsteps_array2 nextObject]) {
        [trip_array2 addObject: [step2 objectAtIndex:0]];
    }
    
    NSMutableSet* set1 = [NSMutableSet setWithArray:trip_array];
    NSMutableSet* set2 = [NSMutableSet setWithArray:trip_array2];
    
    [set1 intersectSet:set2];
    
    
    if ([[set1 allObjects] count]>0) {
        //        NSString *trip_id = [[set1 allObjects] objectAtIndex:0];
        //        NSString *query3 = [NSString stringWithFormat:@"SELECT stops.stop_id, stops.stop_name, stops.stop_lat, stops.stop_lon , stop_times.stop_sequence FROM stops JOIN stop_times ON stop_times.trip_id = '%@' AND stop_times.stop_id = stops.stop_id", trip_id];
        //
        //        NSLog(@"q3");
        //        NSArray *results3 = [self loadDataFromDB:query3];
        //        NSLog(@"q4");
        //        NSLog(@"results3:%@", results3);
        
        //        return results3;
        return [NSArray arrayWithArray:[set1 allObjects]];;
    }
    
    return nil;
    
}

- (NSString *)getTripIDFromRouteDic:(NSMutableDictionary *)route_dic step_index:(int)step_index {
    // Parse the route dictionary
    NSMutableDictionary *leg_array = [[route_dic objectForKey:@"legs"] objectAtIndex:0];
    
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    
    if([steps_array count]>step_index) {
        NSMutableDictionary *one_step = [steps_array objectAtIndex:step_index];
        
        if ([[one_step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            NSString *departure_stop_name = [[[one_step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"name"];
            
            NSString *arrival_stop_name = [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_stop"] objectForKey:@"name"];
            
            NSString *route_short_name = [[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"short_name"];
            NSString *route_long_name = [[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"name"];
            
            // Get time for time zone
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
            
            // Time zone
            NSTimeZone *GMT_tz = [NSTimeZone timeZoneWithName:@"GMT"];
            [formatter setTimeZone:GMT_tz];
            
            NSString *departure_time_zone = [[[one_step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"time_zone"];
            NSTimeZone *departure_tz = [NSTimeZone timeZoneWithName:departure_time_zone];
            NSDate *nsdate_departure_time = [formatter dateFromString: [[[one_step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"value"]];
            
            NSString *arrival_time_zone = [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"time_zone"];
            NSTimeZone *arrival_tz = [NSTimeZone timeZoneWithName:arrival_time_zone];
            NSDate *nsdate_arrive_time = [formatter dateFromString: [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"value"]];
            
            [formatter setDateFormat:@"HH:mm:ss"];
            
            [formatter setTimeZone:departure_tz];
            NSString *start_stop_departure_time = [formatter stringFromDate:nsdate_departure_time];
            NSString *first_character=[start_stop_departure_time substringToIndex:1];
            if ([first_character isEqualToString:@"0"]) {
                start_stop_departure_time = [start_stop_departure_time substringFromIndex:1 ];
            }
            
            [formatter setTimeZone:arrival_tz];
            NSString *end_stop_departure_time = [formatter stringFromDate:nsdate_arrive_time];
            
            // Get Week Day
            [formatter setDateFormat:@"EEEE"];
            [formatter setTimeZone:departure_tz];
            
            [formatter setDateFormat:@"YYYYMMdd"];
            [formatter setTimeZone:departure_tz];
            
//            NSString *query = [NSString stringWithFormat:@"SELECT t.trip_id FROM trips t JOIN calendar c ON t.service_id=c.service_id JOIN routes r ON t.route_id = r.route_id JOIN stop_times  start_st ON t.trip_id = start_st.trip_id JOIN stops start_s ON start_st.stop_id = start_s.stop_id JOIN stop_times end_st ON t.trip_id = end_st.trip_id  JOIN stops end_s ON end_st.stop_id = end_s.stop_id WHERE c.'%@' = 1 AND c.start_date<=%ld AND c.end_date>=%ld AND start_st.departure_time='%@' AND end_st.departure_time='%@' AND ( r.route_long_name='%@' OR r.route_short_name='%@' ) AND start_s.stop_name='%@' AND end_s.stop_name='%@'",
//                               week_day,
//                               (long)start_stop_departure_date, (long)start_stop_departure_date,
//                               start_stop_departure_time, end_stop_departure_time,
//                               route_long_name, route_short_name,
//                               departure_stop_name, arrival_stop_name ];
            
/*            NSString *query = [NSString stringWithFormat:@"SELECT t.trip_id FROM trips t \
                               JOIN calendar c ON t.service_id=c.service_id \
                               JOIN routes r ON t.route_id = r.route_id \
                               JOIN stop_times  start_st ON t.trip_id = start_st.trip_id \
                               JOIN stops start_s ON start_st.stop_id = start_s.stop_id \
                               JOIN stop_times end_st ON t.trip_id = end_st.trip_id \
                               JOIN stops end_s ON end_st.stop_id = end_s.stop_id \
                               JOIN calendar_dates cd ON t.service_id = cd.service_id \
                               WHERE ((c.'%@' = 1 AND c.start_date<=%ld AND c.end_date>=%ld) \
                                      OR (cd.date<=%ld AND cd.date>=%ld AND cd.exception_type=1)) \
                               AND start_st.departure_time='%@' \
                               AND end_st.departure_time='%@' \
                               AND ( r.route_long_name='%@' OR r.route_short_name='%@' ) \
                               AND start_s.stop_name='%@' \
                               AND end_s.stop_name='%@'", \
                               week_day,
                               (long)start_stop_departure_date, (long)start_stop_departure_date,
                               (long)start_stop_departure_date, (long)start_stop_departure_date,
                               start_stop_departure_time, end_stop_departure_time,
                               [route_long_name uppercaseString], [route_short_name uppercaseString],
                               [departure_stop_name uppercaseString], [arrival_stop_name uppercaseString]];
 
 */
            NSString *query = [NSString stringWithFormat:@"SELECT t.trip_id FROM trips t \
                               JOIN stop_times  start_st ON t.trip_id = start_st.trip_id \
                               JOIN stops start_s ON start_st.stop_id = start_s.stop_id \
                               JOIN stop_times end_st ON t.trip_id = end_st.trip_id \
                               JOIN stops end_s ON end_st.stop_id = end_s.stop_id \
                               JOIN routes r ON t.route_id = r.route_id \
                               WHERE start_st.departure_time='%@' \
                               AND start_s.stop_name='%@' \
                               AND end_st.departure_time='%@' \
                               AND end_s.stop_name='%@' \
                               AND r.route_long_name='%@' OR r.route_short_name='%@'",
                               start_stop_departure_time,
                               [departure_stop_name uppercaseString],
                               end_stop_departure_time,
                               [arrival_stop_name uppercaseString],
                               [route_long_name uppercaseString], [route_short_name uppercaseString]];
            
            NSLog(@"getTripIDFromRouteDicquery:%@", query);
            
            NSArray *results = [self loadDataFromDB:query];
            
            NSLog(@"getTripIDFromRouteDic:%@", results);
            
            if (results && [results count]>0 && (results[0])[0]) {
                return [NSString stringWithFormat:@"%@",(results[0])[0] ];
            } else
                return nil;
        }
    }
    // 
    return nil;
}

- (NSString *)getStop_idFromRoute:(NSMutableDictionary *)route_dic step_index:(int)step_index {
    // Parse the route dictionary
    NSMutableDictionary *leg_array = [[route_dic objectForKey:@"legs"] objectAtIndex:0];
    
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    
    if([steps_array count]>step_index) {
        NSMutableDictionary *one_step = [steps_array objectAtIndex:step_index];
        
        if ([[one_step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
                
                NSString *departure_stop_name = [[[one_step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"name"];
                
                double d = [[[[[[one_step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"location"] allValues] objectAtIndex:0] doubleValue];
                NSString *departure_stop_lat = [self roundDouble:d];
                d = [[[[[[one_step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"location"] allValues] objectAtIndex:1] doubleValue];
                NSString *departure_stop_lon = [self roundDouble:d];
            
            NSString *query = [NSString stringWithFormat:@"SELECT stop_id FROM stops WHERE stops.stop_name='%@' AND stops.stop_lat='%@' AND stops.stop_lon='%@'", departure_stop_name, departure_stop_lat, departure_stop_lon ];
            
            NSArray *results = [[self loadDataFromDB:query] copy];
            
            if (results && [results count]>0 && (results[0])[0]) {
                return [NSString stringWithFormat:@"%@",(results[0])[0] ];
            } else
                return nil;
        }
    }
    return nil;
}

                

- (NSArray *)getTripIDFromRoute:(NSMutableDictionary *)route_dic step_index:(int)step_index {
    // Parse the route dictionary
    NSMutableDictionary *leg_array = [[route_dic objectForKey:@"legs"] objectAtIndex:0];
    
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    
    if([steps_array count]>step_index) {
        NSMutableDictionary *one_step = [steps_array objectAtIndex:step_index];
        
        if ([[one_step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            // Get route id
            NSString *route_short_name = [[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"short_name"];
            NSString *route_long_name = [[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"name"];
            
            NSString *route_id = [self getRouteID:route_long_name route_short_name:route_short_name];
            
            // Get trip id
            if (route_id) {
                
                NSString *departure_stop_name = [[[one_step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"name"];
                
                double d = [[[[[[one_step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"location"] allValues] objectAtIndex:0] doubleValue];
                NSString *departure_stop_lat = [self roundDouble:d];
                d = [[[[[[one_step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"location"] allValues] objectAtIndex:1] doubleValue];
                NSString *departure_stop_lon = [self roundDouble:d];
                
                NSString *arrival_stop_name = [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_stop"] objectForKey:@"name"];
                d=[[[[[[one_step objectForKey:@"transit"] objectForKey:@"arrival_stop"] objectForKey:@"location"] allValues] objectAtIndex:0] doubleValue];
                NSString *arrival_stop_lat = [self roundDouble:d];
                
                d=[[[[[[one_step objectForKey:@"transit"] objectForKey:@"arrival_stop"] objectForKey:@"location"] allValues] objectAtIndex:1] doubleValue];
                NSString *arrival_stop_lon = [self roundDouble:d];
                
                
                // Get time for time zone
                NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
                
                // Time zone
                NSTimeZone *GMT_tz = [NSTimeZone timeZoneWithName:@"GMT"];
                [formatter setTimeZone:GMT_tz];
                
                NSString *departure_time_zone = [[[one_step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"time_zone"];
                NSTimeZone *departure_tz = [NSTimeZone timeZoneWithName:departure_time_zone];
                //                [formatter setTimeZone:departure_tz];
                
                NSDate *nsdate_departure_time = [formatter dateFromString: [[[one_step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"value"]];
                
                NSString *arrival_time_zone = [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"time_zone"];
                NSTimeZone *arrival_tz = [NSTimeZone timeZoneWithName:arrival_time_zone];
                //                [formatter setTimeZone:arrival_tz];
                
                NSDate *nsdate_arrive_time = [formatter dateFromString: [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"value"]];
                
                [formatter setDateFormat:@"hh:mm"];
                
                [formatter setTimeZone:departure_tz];
                NSString *departure_time = [[formatter stringFromDate:nsdate_departure_time] stringByAppendingString:@":00"];
                
                [formatter setTimeZone:arrival_tz];
                NSString *arrive_time = [[formatter stringFromDate:nsdate_arrive_time] stringByAppendingString:@":00"];
                
                
                return [self getTripID:route_id departure_stop_name:departure_stop_name departure_stop_lat:departure_stop_lat departure_stop_lon:departure_stop_lon arrival_stop_name:arrival_stop_name arrival_stop_lat:arrival_stop_lat arrival_stop_lon:arrival_stop_lon departure_time:departure_time arrival_time:arrive_time];
                
            }
        }
    }
    return nil;
}

// Round double
- (NSString *)roundDouble:(double)toRound {
    short precision = 6;
    NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                             scale:precision
                                                                                  raiseOnExactness:NO
                                                                                   raiseOnOverflow:NO
                                                                                  raiseOnUnderflow:NO
                                                                               raiseOnDivideByZero:NO];
    double rounded = [[[NSDecimalNumber decimalNumberWithString:[[NSNumber numberWithDouble:toRound] stringValue]] decimalNumberByRoundingAccordingToBehavior:handler] doubleValue];
    return [NSString stringWithFormat:@"%.6f", rounded ];
}

- (NSMutableDictionary *)getNearbyStops:(float)distance_meters lat:(double)lat lon:(double)lon {
    
    NSString *query = [NSString stringWithFormat:@"SELECT stop_id, stop_name, stop_lat, stop_lon FROM stops" ];
    
    NSArray *results = [[self loadDataFromDB:query] copy];
    
//    NSMutableArray *stop_array = [[NSMutableArray alloc] initWithCapacity:5];
    
    NSMutableDictionary *stops_dictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    NSEnumerator *enmuerator_stop_array = [results objectEnumerator];
    NSMutableArray *stop;
    while (stop = [enmuerator_stop_array nextObject]) {
        double stop_lat = [[stop objectAtIndex:2] doubleValue];
        double stop_lon = [[stop objectAtIndex:3] doubleValue];
        
        CLLocation *locA = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
        
        CLLocation *locB = [[CLLocation alloc] initWithLatitude:stop_lat longitude:stop_lon];
        
        CLLocationDistance cLLocationDistance = [locA distanceFromLocation:locB];
        
        NSString *distanceString = [[NSString alloc] initWithFormat: @"%f", cLLocationDistance];
        
        float totaldistancecovered = [distanceString floatValue];
        
        if (totaldistancecovered<distance_meters) {
//            NSMutableDictionary *one_stop = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%@",[stop objectAtIndex:0]], [NSString stringWithFormat:@"%@",[stop objectAtIndex:1]], [NSNumber numberWithFloat:totaldistancecovered], nil] forKeys:[NSArray arrayWithObjects:@"stop_id", @"stop_name", @"stop_distance", nil]];
            
            NSMutableDictionary *one_stop2 = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects: [NSString stringWithFormat:@"%@",[stop objectAtIndex:1]], [NSNumber numberWithFloat:totaldistancecovered], nil] forKeys:[NSArray arrayWithObjects: @"stop_name", @"stop_distance", nil]];
            
            
            [stops_dictionary setObject:one_stop2 forKey: [NSString stringWithFormat:@"%@",[stop objectAtIndex:0]]];
            
//            NSLog(@"%f", cLLocationDistance);
            
//            [stop_array addObject:one_stop];
            
//            if ([stop_array count]>=20) {
//                NSLog(@"getNearbyStops: %@",stop_array);
//                return stop_array;
//            }
            
        }
    }
    
//    [stop_array sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"stop_distance" ascending:YES], nil]];
    
//    NSLog(@"getNearbyStops: %@, %lu",stops_dictionary, [[stops_dictionary allKeys] count]);
    return stops_dictionary;
}

-(NSString *)getRouteNameFromId:(NSString *)route_id {
    NSString *query;
    if ([route_id length]==1) {
        route_id = [@" " stringByAppendingString:route_id];
    }
    query = [NSString stringWithFormat:@"SELECT route_long_name FROM routes WHERE route_id='%@'",route_id];
    
    NSArray *results = [[self loadDataFromDB:query] copy];
    
    if (results && [results count]>0 && (results[0])[0]) {
        return [NSString stringWithFormat:@"%@",(results[0])[0] ];
    } else {
        NSString *trimmedString = [route_id stringByReplacingOccurrencesOfString:@" " withString:@""];
//        NSLog(@"1006:%@", [trimmedString isEqualToString:route_id]?@"Equal":@"Not");
        if ([trimmedString isEqualToString:route_id])
            return nil;
        else {
            query = [NSString stringWithFormat:@"SELECT route_long_name FROM routes WHERE route_id='%@'",trimmedString];
            
            NSArray *results = [[self loadDataFromDB:query] copy];
            
            if (results && [results count]>0 && (results[0])[0]) {
                return [NSString stringWithFormat:@"%@",(results[0])[0] ];
            }
        }
    }
    return nil;
}

-(NSString *)getStopNameFromId:(NSString *)stop_id {
    NSString *query;
    
    query = [NSString stringWithFormat:@"SELECT stop_name FROM stops WHERE stop_id='%@'",stop_id];
    
    NSArray *results = [[self loadDataFromDB:query] copy];
    
    if (results && [results count]>0 && (results[0])[0]) {
        return [NSString stringWithFormat:@"%@",(results[0])[0] ];
    } else
        return nil;
}

-(NSString *)getScheduled_trip_id:(NSString *)departureLat departureLng:(NSString *)departureLng arrivalLat:(NSString *)arrivalLat arrivalLng:(NSString *)arrivalLng departureTime:(NSInteger)departureTime arrivalTime:(NSInteger)arrivalTime {
    
    NSString *query = [NSString stringWithFormat:@"SELECT scheduled_trip_id FROM thub_scheduled_trips WHERE departureLat='%@' AND departureLng='%@' AND arrivalLat='%@' AND arrivalLng='%@' AND departureTime=%ld AND arrivalTime=%ld", departureLat, departureLng, arrivalLat, arrivalLng, (long)departureTime, (long)arrivalTime];
    
    NSArray *results = [[self loadDataFromDB:query] copy];
    
    if (results && [results count]>0 && (results[0])[0]) {
        return [NSString stringWithFormat:@"%@",(results[0])[0] ];
    } else
        return nil;
}

// March 18
// New implementation that gets rid of static GTFS
-(NSDictionary *)getTripInformation_new:(NSMutableDictionary *)route_dic step_index:(int)step_index {
    NSMutableDictionary *leg_array = [[route_dic objectForKey:@"legs"] objectAtIndex:0];
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    if([steps_array count]>step_index) {
        NSMutableDictionary *one_step = [steps_array objectAtIndex:step_index];
        if ([[one_step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            NSString *departure_stop_name = [[[one_step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"name"];
            
            NSString *departure_stop_id = @"";
            NSString* query0 = [NSString stringWithFormat:@"SELECT stop_id \
                                FROM stops \
                                WHERE stop_name='%@'",[departure_stop_name uppercaseString]];
            NSArray *results0 = [[self loadDataFromDB:query0] copy];
            NSLog(@"842:%@", results0);
            if (results0!=nil && [results0 count]>0) {
                departure_stop_id = [[results0 objectAtIndex:0] objectAtIndex:0];
            } else
                departure_stop_id = departure_stop_name;
            
            NSString *arrival_stop_name = [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_stop"] objectForKey:@"name"];
            
            NSString *arrival_stop_id = @"";
            query0 = [NSString stringWithFormat:@"SELECT stop_id \
                      FROM stops \
                      WHERE stop_name='%@'",[arrival_stop_name uppercaseString]];
            results0 = [[self loadDataFromDB:query0] copy];
            NSLog(@"843:%@", results0);
            if (results0!=nil && [results0 count]>0) {
                arrival_stop_id = [[results0 objectAtIndex:0] objectAtIndex:0];
            } else
                arrival_stop_id = arrival_stop_name;
            
            NSString *route_short_name = [[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"short_name"];
            NSString *route_long_name = [[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"name"];
            NSString * headsign = [[one_step objectForKey:@"transit"] objectForKey: @"headsign"];
            
            // Get time for time zone
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
            
            // Time zone
            NSTimeZone *GMT_tz = [NSTimeZone timeZoneWithName:@"GMT"];
            [formatter setTimeZone:GMT_tz];
            
            NSString *departure_time_zone = [[[one_step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"time_zone"];
            NSTimeZone *departure_tz = [NSTimeZone timeZoneWithName:departure_time_zone];
            NSDate *nsdate_departure_time = [formatter dateFromString: [[[one_step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"value"]];
            
            NSString *arrival_time_zone = [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"time_zone"];
            NSTimeZone *arrival_tz = [NSTimeZone timeZoneWithName:arrival_time_zone];
            NSDate *nsdate_arrive_time = [formatter dateFromString: [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"value"]];
            
            NSMutableDictionary *returnDic = [[NSMutableDictionary alloc] initWithCapacity:5];
//            [returnDic setValue:oneResult[0] forKey:@"trip_id"];
            [returnDic setValue:[departure_stop_name uppercaseString] forKey:@"start_stop_name"];
            [returnDic setValue:[arrival_stop_name uppercaseString] forKey:@"end_stop_name"];
            [returnDic setValue:[NSNumber numberWithDouble:[nsdate_departure_time timeIntervalSince1970] ]forKey:@"start_stop_timestamp"];
            [returnDic setValue:[NSNumber numberWithDouble:[nsdate_arrive_time timeIntervalSince1970] ]forKey:@"end_stop_timestamp"];
            [returnDic setValue:route_short_name forKey:@"route_id"];
            
            [returnDic setValue:[headsign uppercaseString] forKey:@"headsign"];
            [returnDic setValue:[NSNumber numberWithInt:step_index] forKey:@"step_index"];
            
            [returnDic setValue:departure_stop_id forKey:@"departure_stop_id"];
            [returnDic setValue:arrival_stop_id forKey:@"arrival_stop_id"];
            
            
//            NSLog(@"returnDic1001: %@", returnDic);
            return returnDic;
        }
    }
    return nil;
}

//
//- (void)
-(NSDictionary *)getTripInformationFromRouteDictionary:(NSMutableDictionary *)route_dic step_index:(int)step_index {
    // Parse the route dictionary
    NSMutableDictionary *leg_array = [[route_dic objectForKey:@"legs"] objectAtIndex:0];
    
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    
//    NSLog(@"TEST::: steps_array::: %lu,%d", (unsigned long)[steps_array count], step_index);
    
    if([steps_array count]>step_index) {
        NSMutableDictionary *one_step = [steps_array objectAtIndex:step_index];
//        NSLog(@"T756:%@",one_step);
        
        if ([[one_step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            NSString *departure_stop_name = [[[one_step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"name"];
            
            NSString *arrival_stop_name = [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_stop"] objectForKey:@"name"];
            
            
            
            NSString *route_short_name = [[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"short_name"];
            NSString *route_long_name = [[[one_step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"name"];
            
            // Get time for time zone
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
            
            // Time zone
            NSTimeZone *GMT_tz = [NSTimeZone timeZoneWithName:@"GMT"];
            [formatter setTimeZone:GMT_tz];
            
            NSString *departure_time_zone = [[[one_step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"time_zone"];
            NSTimeZone *departure_tz = [NSTimeZone timeZoneWithName:departure_time_zone];
            NSDate *nsdate_departure_time = [formatter dateFromString: [[[one_step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"value"]];
            
            NSString *arrival_time_zone = [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"time_zone"];
            NSTimeZone *arrival_tz = [NSTimeZone timeZoneWithName:arrival_time_zone];
            NSDate *nsdate_arrive_time = [formatter dateFromString: [[[one_step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"value"]];
            
            [formatter setDateFormat:@"HH:mm:ss"];
            
            [formatter setTimeZone:departure_tz];
            NSString *start_stop_departure_time = [formatter stringFromDate:nsdate_departure_time];
            NSString *first_character=[start_stop_departure_time substringToIndex:1];
//            if ([first_character isEqualToString:@"0"]) {
//                start_stop_departure_time = [start_stop_departure_time stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@" "];
//            }
            
            [formatter setTimeZone:arrival_tz];
            NSString *end_stop_departure_time = [formatter stringFromDate:nsdate_arrive_time];
            first_character=[end_stop_departure_time substringToIndex:1];
//            if ([first_character isEqualToString:@"0"]) {
//                end_stop_departure_time = [end_stop_departure_time stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@" "];
//            }
            
            // Get Week Day
            [formatter setDateFormat:@"EEEE"];
            [formatter setTimeZone:departure_tz];
            
            [formatter setDateFormat:@"YYYYMMdd"];
            [formatter setTimeZone:departure_tz];
//            NSString *query0 = [NSString stringWithFormat:@"SELECT t.trip_id, r.route_id, start_st.stop_sequence, end_st.stop_sequence FROM trips t \
//                               JOIN stop_times  start_st ON t.trip_id = start_st.trip_id \
//                               JOIN stops start_s ON start_st.stop_id = start_s.stop_id \
//                               JOIN stop_times end_st ON t.trip_id = end_st.trip_id \
//                               JOIN stops end_s ON end_st.stop_id = end_s.stop_id \
//                               JOIN routes r ON t.route_id = r.route_id \
//                               WHERE start_st.departure_time='%@' \
//                               AND start_s.stop_name='%@' \
//                               AND end_st.departure_time='%@' \
//                               AND end_s.stop_name='%@' \
//                               AND (r.route_long_name='%@' OR r.route_short_name='%@')",
//                               start_stop_departure_time,
//                               [departure_stop_name uppercaseString],
//                               end_stop_departure_time,
//                               [arrival_stop_name uppercaseString],
//                               [route_long_name uppercaseString], [route_short_name uppercaseString]];
            
            NSString* query0 = [NSString stringWithFormat:@"SELECT start_st.trip_id \
                     FROM stop_times start_st \
                     LEFT JOIN stops start_s ON start_st.stop_id = start_s.stop_id \
                     WHERE start_st.departure_time='%@' AND start_s.stop_name='%@'",
                     start_stop_departure_time, [departure_stop_name uppercaseString]];
            
//            query0 = [NSString stringWithFormat:@"SELECT * \
                      FROM routes"];
            
            NSLog(@"T803:%@ ", query0);
            NSArray *results0 = [[self loadDataFromDB:query0] copy];
            NSLog(@"T748:%@", results0);
            
            if (results0!=nil)
            for (NSArray *trip_id_array in results0) {
                NSString *trip_id1 = [NSString stringWithFormat:@"%@",[trip_id_array objectAtIndex:0]];
                
                NSString *query_start_stop_sequence = [NSString stringWithFormat:@"SELECT stop_sequence FROM stop_times \
                                                       WHERE trip_id='%@' AND departure_time='%@'",
                                                       trip_id1, start_stop_departure_time];
                
                NSArray *results_start_stop_sequence = [[self loadDataFromDB:query_start_stop_sequence] copy];
                
                NSLog(@"t1011:%@, %@", query_start_stop_sequence, results_start_stop_sequence);
                if (results_start_stop_sequence!=nil)
                    if ([results_start_stop_sequence count]>0)
                        if ([results_start_stop_sequence[0] count]>0) {
                            NSString *start_stop_sequence = (results_start_stop_sequence[0])[0];
                            
                            NSString *query1 = [NSString stringWithFormat:@"SELECT t.trip_id, r.route_id, end_st.stop_sequence, end_st.stop_sequence FROM trips t \
                                                JOIN stop_times end_st ON t.trip_id = end_st.trip_id \
                                                JOIN stops end_s ON end_st.stop_id = end_s.stop_id \
                                                JOIN routes r ON t.route_id = r.route_id \
                                                WHERE end_st.departure_time='%@' \
                                                AND end_s.stop_name='%@' \
                                                AND (r.route_long_name='%@' OR r.route_short_name='%@') \
                                                AND t.trip_id='%@'",
                                                end_stop_departure_time,
                                                [arrival_stop_name uppercaseString],
                                                [route_long_name uppercaseString], [route_short_name uppercaseString],
                                                trip_id1];
                            
                            NSLog(@"T952:%@ ", query1);
                            NSArray *results1 = [[self loadDataFromDB:query1] copy];
                            NSLog(@"T953:%@, %lu", results1, (unsigned long)[results1 count]);
                            
                            for (NSArray *oneResult in results1) {
                                if (oneResult && [oneResult count]>=4 && oneResult[0]) {
                                    if([[NSString stringWithFormat:@"%@",[oneResult objectAtIndex:1]] length]>20)
                                        continue;
                                    NSMutableDictionary *returnDic = [[NSMutableDictionary alloc] initWithCapacity:5];
                                    [returnDic setValue:oneResult[0] forKey:@"trip_id"];
                                    [returnDic setValue:[departure_stop_name uppercaseString] forKey:@"start_stop_name"];
                                    [returnDic setValue:[arrival_stop_name uppercaseString] forKey:@"end_stop_name"];
                                    [returnDic setValue:[NSNumber numberWithDouble:[nsdate_departure_time timeIntervalSince1970] ]forKey:@"start_stop_timestamp"];
                                    [returnDic setValue:[NSNumber numberWithDouble:[nsdate_arrive_time timeIntervalSince1970] ]forKey:@"end_stop_timestamp"];
                                    [returnDic setValue:oneResult[1] forKey:@"route_id"];
                                    
                                    
                                    
                                    [returnDic setValue:start_stop_sequence forKey:@"start_stop_sequence"];
                                    [returnDic setValue:oneResult[3] forKey:@"end_stop_sequence"];
                                    [returnDic setValue:[NSNumber numberWithInt:step_index] forKey:@"step_index"];
                                    
                                    NSLog(@"returnDic1001: %@", returnDic);
                                    return returnDic;
                                }
                            }
                        }
            }
        }
    }
    //
//    NSLog(@"TEST::: return nil!");
    return nil;
}

-(BOOL)checkIfSameRoute:(NSString *)route_id trip_id:(NSString *)trip_id {
    NSString *query = [NSString stringWithFormat:@"SELECT route_id FROM trips WHERE route_id='%@' AND trip_id='%@'", route_id, trip_id];
    
    NSArray *results = [[self loadDataFromDB:query] copy];
    
    if (results && [results count]>0 && (results[0])[0]) {
        return YES;
    } else
        return NO;
}

-(NSString *)getRouteIDFromTripID: (NSString *)tripID {
    NSString *query = [NSString stringWithFormat:@"SELECT route_id FROM trips WHERE trip_id='%@'", tripID];
    
    NSArray *results = [[self loadDataFromDB:query] copy];
    
    if (results && [results count]>0 && (results[0])[0]) {
        return (results[0])[0];
    } else
        return nil;
}

-(NSArray *)getShapeArrayFromTripID:(NSString *)tripId {
    NSString *query = [NSString stringWithFormat:@"SELECT shape_id FROM trips WHERE trip_id='%@'", tripId];
    
    NSArray *results = [[self loadDataFromDB:query] copy];
    
    if (results && [results count]>0 && (results[0])[0]) {
        NSString *shape_id = (results[0])[0];
        
        query = [NSString stringWithFormat:@"SELECT shape_pt_lat, shape_pt_lon, shape_dist_traveled FROM shapes WHERE shape_id='%@'", shape_id];
        results = [[self loadDataFromDB:query] copy];
        
        if (results && [results count]>0)
            return results;
    }
    
    return nil;

}

-(NSArray *)getCoorFromStopId:(NSString *)stopId {
    NSString *query = [NSString stringWithFormat:@"SELECT stop_lat, stop_lon FROM stops WHERE stop_id='%@'", stopId];
    
    NSArray *results = [[self loadDataFromDB:query] copy];
    
    if (results && [results count]>0 && (results[0])[0] && (results[0])[1]) {
        return results[0];
    }
    
    return nil;
    
}

// Route Query View
-(NSString *)getTripHeadSignByTripID: (NSString *)tripID {
//    NSArray *results2 = [[self loadDataFromDB:@"SELECT * FROM trips WHERE trip_id=10326"] copy];

    
    NSString *query = [NSString stringWithFormat:@"SELECT trip_headsign FROM trips WHERE trip_id=%@", tripID];
    
    NSArray *results = [[self loadDataFromDB:query] copy];
//    NSLog(@"results2:%@", results[0]);
    
    if (results && [results count]>0 && (results[0])[0]) {
        return (results[0])[0];
    }
    
    return nil;
}
- (NSArray *)getStopsByTripID: (NSString *)tripID {
    NSString *query = [NSString stringWithFormat:@"SELECT st.stop_sequence, st.stop_id, s.stop_name, s.stop_lat, s.stop_lon FROM stop_times st JOIN stops s ON st.stop_id=s.stop_id WHERE trip_id='%@'", tripID];
    NSArray *results = [[self loadDataFromDB:query] copy];
    NSMutableArray *nSMArray_stops = [[NSMutableArray alloc] init];
    
    if (results && [results count]>0) {
        for (NSArray *stop in results) {
            NSMutableDictionary *nSMDic_stop = [[NSMutableDictionary alloc] initWithCapacity:5];
            [nSMDic_stop setObject:stop[0] forKey:@"stop_sequence"];
            [nSMDic_stop setObject:stop[1] forKey:@"stop_id"];
            [nSMDic_stop setObject:stop[2] forKey:@"stop_name"];
            [nSMDic_stop setObject:stop[3] forKey:@"stop_lat"];
            [nSMDic_stop setObject:stop[4] forKey:@"stop_lon"];
            [nSMArray_stops addObject:nSMDic_stop];
//            NSLog(@"TMP::: %@", nSMDic_stop);
        }
        return [nSMArray_stops copy];
    }
    return nil;
}
- (NSMutableArray *)getDepartureAndArrivalTimeByTripID: (NSString *)tripID {
    NSMutableArray *array_return = [[NSMutableArray alloc] initWithCapacity:2];
        NSString *query = [NSString stringWithFormat:@"SELECT departure_time FROM stop_times WHERE trip_id='%@' ORDER BY stop_sequence ASC", tripID];
        
        NSArray *results = [[self loadDataFromDB:query] copy];
        
        if (results && [results count]>0 && (results[0])[0]) {
            [array_return addObject: [([results firstObject])[0] substringToIndex:5] ];
            [array_return addObject:[([results lastObject])[0] substringToIndex:5] ];
            return array_return;
        }
    return nil;
}

- (NSInteger)getNumStopsByTripID:(NSString *)tripID {
    NSString *query = [NSString stringWithFormat:@"SELECT stop_sequence, stop_id FROM stop_times WHERE trip_id='%@'", tripID];
    NSArray *results = [[self loadDataFromDB:query] copy];
    
    if (results && [results count]>0) {
        return [results count];
    }
    return 0;
}

- (NSMutableDictionary *)getStaticTimeStringByTripID:(NSString *)tripID andStopID:(NSString *)stopID {
    NSString *query = [NSString stringWithFormat:@"SELECT departure_time, stop_sequence FROM stop_times WHERE trip_id='%@' AND stop_id='%@'", tripID, stopID];
    NSArray *results = [[self loadDataFromDB:query] copy];
    
    if (results && [results count]>0) {
        NSString *rawTime = results[0][0];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH:mm:ss";
        NSDate *date = [dateFormatter dateFromString:rawTime];
        
        dateFormatter.dateFormat = @"hh:mm a";
        NSString *pmamDateString = [dateFormatter stringFromDate:date];
        
        NSMutableDictionary *returnDic = [[NSMutableDictionary alloc] init];
        [returnDic setObject:pmamDateString forKey:@"departure_time"];
        [returnDic setObject:[NSNumber numberWithInteger:[(results[0])[1] integerValue] ] forKey:@"stop_sequence"];
        return returnDic;
    }
    return nil;
}

@end
