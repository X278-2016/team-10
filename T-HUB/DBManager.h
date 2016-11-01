//
//  DBManager.h
//  GCTC
//
//  Created by Fangzhou Sun on 3/9/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBManager : NSObject
-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename;

@property (nonatomic, strong) NSMutableArray *arrColumnNames;

@property (nonatomic) int affectedRows;

@property (nonatomic) long long lastInsertedRowID;

-(NSArray *)loadDataFromDB:(NSString *)query;

-(void)executeQuery:(NSString *)query;

//
-(NSString *)getRouteID:(NSString *)route_long_name route_short_name:(NSString *)route_short_name;

-(NSString *)getRouteIDFromRouteDic:(NSMutableDictionary *)route_dic step_index:(int)step_index;

//-(NSArray *)getStops:(NSString *)route_id departure_stop_name:(NSString *)departure_stop_name departure_stop_lat:(NSString *)departure_stop_lat departure_stop_lon:(NSString *)departure_stop_lon arrival_stop_name:(NSString *)arrival_stop_name arrival_stop_lat:(NSString *)arrival_stop_lat arrival_stop_lon:(NSString *)arrival_stop_lon departure_time:(NSString *)departure_time arrival_time:(NSString *)arrival_time;

- (NSArray *)getTripIDFromRoute:(NSMutableDictionary *)route_dic step_index:(int)step_index;


- (NSString *)getTripIDFromRouteDic:(NSMutableDictionary *)route_dic step_index:(int)step_index;

- (NSString *)getStop_idFromRoute:(NSMutableDictionary *)route_dic step_index:(int)step_index;

- (NSMutableDictionary *)getNearbyStops:(float)distance_meters lat:(double)lat lon:(double)lon;

-(NSString *)getStopNameFromId:(NSString *)stop_id;

-(NSString *)getScheduled_trip_id:(NSString *)departureLat departureLng:(NSString *)departureLng arrivalLat:(NSString *)arrivalLat arrivalLng:(NSString *)arrivalLng departureTime:(NSInteger)departureTime arrivalTime:(NSInteger)arrivalTime;

-(NSDictionary *)getTripInformationFromRouteDictionary:(NSMutableDictionary *)route_dic step_index:(int)step_index;
-(BOOL)checkIfSameRoute:(NSString *)route_id trip_id:(NSString *)trip_id;

-(NSString *)getRouteIDFromTripID: (NSString *)tripID;

-(NSArray *)getShapeArrayFromTripID:(NSString *)tripId;
-(NSArray *)getCoorFromStopId:(NSString *)stopId;

// Route Query View
- (NSString *)getTripHeadSignByTripID: (NSString *)tripID;
- (NSArray *)getStopsByTripID: (NSString *)tripID;
//- (NSString *)getDepartureTimeByTripID: (NSString *)tripID;
- (NSMutableArray *)getDepartureAndArrivalTimeByTripID: (NSString *)tripID;
-(NSString *)getRouteNameFromId:(NSString *)route_id;

-(NSDictionary *)getTripInformation_new:(NSMutableDictionary *)route_dic step_index:(int)step_index;
- (NSInteger)getNumStopsByTripID:(NSString *)tripID;
- (NSMutableDictionary *)getStaticTimeStringByTripID:(NSString *)tripID andStopID:(NSString *)stopID;
@end
