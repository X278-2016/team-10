//
//  JSONParser.m
//  T-HUB
//
//  Created by Fangzhou Sun on 5/7/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "JSONParser.h"

@implementation JSONParser

- (NSMutableDictionary *)getRouteDetails:(NSMutableDictionary *)route_dic {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    NSMutableDictionary *leg_array = [(NSMutableArray *)[route_dic objectForKey:@"legs"] objectAtIndex:0];
    
    [result setValue: [leg_array objectForKey:@"start_address"] forKey:@"start_address"];
    [result setValue: [leg_array objectForKey:@"end_address"] forKey:@"end_address"];
    
    // Change time to local time
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    
    NSDate * Preferred_departure_time = [formatter dateFromString:[[leg_array objectForKey:@"departure_time"] objectForKey:@"value"]];
    
    NSDate * Preferred_arrival_time = [formatter dateFromString:[[leg_array objectForKey:@"arrival_time"] objectForKey:@"value"]];
    
    //departure_time
    NSInteger t1 = [Preferred_departure_time timeIntervalSince1970];
    [result setValue: [NSString stringWithFormat:@"%.0ld", (long)t1 ] forKey:@"departure_timestamp"];

    //arrival_time
    NSInteger t2 = [Preferred_arrival_time timeIntervalSince1970];
    [result setValue:[NSString stringWithFormat:@"%.0ld", (long)t2 ] forKey:@"arrival_timestamp"];

    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"hh:mma"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setLocale:locale];
    
    // Result Start Time
    if (Preferred_departure_time) {
        [result setValue:[df stringFromDate: Preferred_departure_time] forKey:@"start_time"];
        [result setValue:Preferred_departure_time forKey:@"date_start_time"];
    } else
        [result setValue:@"" forKey:@"start_time"];
    // Result End Time
    if (Preferred_arrival_time) {
        [result setValue:[NSString stringWithFormat:@"-%@", [df stringFromDate: Preferred_arrival_time]] forKey:@"end_time"];
        [result setValue:Preferred_arrival_time forKey:@"date_end_time"];
    } else
        [result setValue:@"" forKey:@"end_time"];
    
    [df setDateFormat:@"MMM dd"];
    
    // Result Date
    if (Preferred_departure_time)
        [result setValue:[df stringFromDate: Preferred_departure_time] forKey:@"date"];
    else
        [result setValue:@"Walking" forKey:@"date"];
    
    float walking_time = 0.0;
    float transit_distance_mile = 0.0;
    float walking_distance_meter = 0.0;
    
    NSMutableDictionary *routeIDDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    NSString *route_details = @"";
    NSMutableArray *route_details_array = [[NSMutableArray alloc] init];
    
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    NSEnumerator *enmueratorsteps_array = [steps_array objectEnumerator];
    NSMutableDictionary *step;
    int index_firstTransitStep = -1;
    int index_step = -1;
    while (step = [enmueratorsteps_array nextObject]) {
        index_step++;
        if (![route_details isEqualToString:@""]) {
            route_details = [route_details stringByAppendingString:@" >"];
            [route_details_array addObject:@"->"];
        }
        
        if ([[step objectForKey:@"travel_mode"] isEqualToString:@"WALKING"]) {
            route_details = [route_details stringByAppendingString:@" \U0001F6B6"];
            [route_details_array addObject:@"UNICODE\U0001F6B6"];
            
            walking_time = walking_time + [[[step objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60;
            walking_distance_meter += [[[step objectForKey:@"distance"] objectForKey:@"value"] floatValue];
        } else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            
            if (index_firstTransitStep<0) {
                index_firstTransitStep = index_step;
            }
            
            transit_distance_mile += [[[step objectForKey:@"distance"] objectForKey:@"value"] floatValue]/1609;
            
            route_details = [route_details stringByAppendingString:@" \U0001F68C"];
            [route_details_array addObject:@"UNICODE \U0001F68C "];
            
            NSString *short_name = [[[step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"short_name"];
            NSString *name = [[[step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"name"];
            
            if (short_name) {
                route_details = [route_details stringByAppendingString:short_name];
                [route_details_array addObject:[NSString stringWithFormat:@"%@ ", short_name]];
                [routeIDDictionary setObject:@"1" forKey:short_name];
            } else if (name) {
                route_details = [route_details stringByAppendingString:name];
                [route_details_array addObject:[NSString stringWithFormat:@"%@ ", name]];
                [routeIDDictionary setObject:@"1" forKey:name];
            }
        }
    }
    
    [result setValue:[NSNumber numberWithInt:index_firstTransitStep] forKey:@"index_firstTransitStep"];
    [result setValue:[routeIDDictionary allKeys] forKey:@"routeIDs"];
    [result setValue:route_details forKey:@"route_details"];
    [result setValue:route_details_array forKey:@"route_details_array"];
    
    [result setValue: [NSString stringWithFormat:@"Calories: %.0f", 0.057*walking_distance_meter] forKey:@"CaloriesToBurn" ];
    [result setValue: [NSString stringWithFormat:@"%.0f", 0.057*walking_distance_meter] forKey:@"CaloriesToBurn_number" ];
     
     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
     NSNumber *gasPrice = [defaults valueForKey:@"gasPrice"];
    [result setValue: [NSString stringWithFormat:@"Gas Saving: $%.1f", [gasPrice floatValue]/24*transit_distance_mile] forKey:@"GasSaving"];
    [result setValue: [NSNumber numberWithFloat: transit_distance_mile] forKey:@"transit_distance_miles_number"];
    
    [result setValue:[NSString stringWithFormat:@"Total: %.1fmin Walk: %.1fmin", [[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60, walking_time ] forKey:@"route_times"];
    
    [result setValue:[NSString stringWithFormat:@"%.1f mins", [[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60] forKey:@"total_time"];
    [result setValue:[NSString stringWithFormat:@"%.1f mins", walking_time ] forKey:@"walk_time"];
    
    [result setValue:[NSString stringWithFormat:@"MTA Points: %.0f",([[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60-walking_time )*2] forKey:@"mta_points"];
    [result setValue:[NSString stringWithFormat:@"Carbon Credits: %.0f",([[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60-walking_time )*1] forKey:@"carbon_credits"];
    
    [result setValue:[NSString stringWithFormat:@"%.0f pts",([[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60-walking_time )*2] forKey:@"mta_points_map"];
    [result setValue:[NSString stringWithFormat:@"%.0f pts",([[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60-walking_time )*1] forKey:@"carbon_credits_map"];

    
    return result;
    
}

- (NSMutableDictionary *)getRouteDetailsForDataCollection:(NSMutableDictionary *)route_dic {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    NSMutableDictionary *leg_array = [(NSMutableArray *)[route_dic objectForKey:@"legs"] objectAtIndex:0];
    
    // Change time to local time
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    
    NSDate * Preferred_departure_time = [formatter dateFromString:[[leg_array objectForKey:@"departure_time"] objectForKey:@"value"]];
    
    NSDate * Preferred_arrival_time = [formatter dateFromString:[[leg_array objectForKey:@"arrival_time"] objectForKey:@"value"]];
    
    //departure_time
    NSInteger t1 = [Preferred_departure_time timeIntervalSince1970];
    [result setValue: [NSString stringWithFormat:@"%.0ld", (long)t1 ] forKey:@"departure_timestamp"];
    
    //arrival_time
    NSInteger t2 = [Preferred_arrival_time timeIntervalSince1970];
    [result setValue:[NSString stringWithFormat:@"%.0ld", (long)t2 ] forKey:@"arrival_timestamp"];
    
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"hh:mma"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setLocale:locale];
    
    // Result Start Time
    if (Preferred_departure_time)
        [result setValue:[df stringFromDate: Preferred_departure_time] forKey:@"start_time"];
    else
        [result setValue:@"" forKey:@"start_time"];
    // Result End Time
    if (Preferred_arrival_time)
        [result setValue:[NSString stringWithFormat:@"-%@", [df stringFromDate: Preferred_arrival_time]] forKey:@"end_time"];
    else
        [result setValue:@"" forKey:@"end_time"];
    
    [df setDateFormat:@"MMM dd"];
    
    // Result Date
    if (Preferred_departure_time)
        [result setValue:[df stringFromDate: Preferred_departure_time] forKey:@"date"];
    else
        [result setValue:@"Walking" forKey:@"date"];
    
    float walking_time = 0.0;
    
    NSString *route_details = @"";
    
    NSMutableArray *resultForSaveItinerary = [[NSMutableArray alloc] initWithCapacity:10];
    
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    NSEnumerator *enmueratorsteps_array = [steps_array objectEnumerator];
    NSMutableDictionary *step;
    while (step = [enmueratorsteps_array nextObject]) {
        if (![route_details isEqualToString:@""]) {
            route_details = [route_details stringByAppendingString:@" >"];
        }
        
        if ([[step objectForKey:@"travel_mode"] isEqualToString:@"WALKING"]) {
            NSMutableDictionary *result2 = [[NSMutableDictionary alloc] initWithCapacity:2];

            float walkDistance = [[[step objectForKey:@"duration"] objectForKey:@"value"] floatValue];
            
            [result2 setValue:[NSNumber numberWithFloat:walkDistance ] forKey:@"walkDistance"];
            [result2 setValue:@"WALKING" forKey:@"travel_mode"];
            [resultForSaveItinerary addObject:result2];
            
            route_details = [route_details stringByAppendingString:@" \U0001F6B6"];
            
            walking_time = walking_time + [[[step objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60;
            
        } else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            NSMutableDictionary *result2 = [[NSMutableDictionary alloc] initWithCapacity:2];
            
            NSDate *departure_date1 = [formatter dateFromString:[[[step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"value"] ];
            [result2 setValue:[NSNumber numberWithInteger:[departure_date1 timeIntervalSince1970]]  forKey:@"departure_time"];
            NSString *departure_stop_name = [[[step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"name"];
            [result2 setValue:departure_stop_name forKey:@"departure_stop_name"];
            
            NSDate *arrival_date1 = [formatter dateFromString:[[[step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"value"] ];
            [result2 setValue:[NSNumber numberWithInteger:[arrival_date1 timeIntervalSince1970]] forKey:@"arrival_time"];
            NSString *arrival_stop_name = [[[step objectForKey:@"transit"] objectForKey:@"arrival_stop"] objectForKey:@"name"];
            [result2 setValue:arrival_stop_name forKey:@"arrival_stop_name"];
            
            [result2 setValue:@"TRANSIT" forKey:@"travel_mode"];
            [resultForSaveItinerary addObject:result2];
        }
    }
    
    
    [result setObject:resultForSaveItinerary forKey:@"resultForSaveItinerary"];
    NSMutableDictionary *result2 = [[NSMutableDictionary alloc] initWithCapacity:2];
    [result2 setValue:[NSNumber numberWithFloat:([[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60-walking_time )*2 ] forKey:@"mta_points"];
    [result2 setValue:[NSNumber numberWithFloat:([[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60-walking_time )*1 ] forKey:@"carbon_credits"];
    [result setObject:result2 forKey:@"incentives"];
    
    
    
    return result;
    
}

- (NSMutableDictionary *)getRouteDetailsForDataCollection_actualTrip:(NSMutableDictionary *)route_dic {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    NSMutableDictionary *leg_array = [(NSMutableArray *)[route_dic objectForKey:@"legs"] objectAtIndex:0];
    
    // Change time to local time
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    
    NSDate * Preferred_departure_time = [formatter dateFromString:[[leg_array objectForKey:@"departure_time"] objectForKey:@"value"]];
    
    NSDate * Preferred_arrival_time = [formatter dateFromString:[[leg_array objectForKey:@"arrival_time"] objectForKey:@"value"]];
    
    //departure_time
    NSInteger t1 = [Preferred_departure_time timeIntervalSince1970];
    [result setValue: [NSString stringWithFormat:@"%.0ld", (long)t1 ] forKey:@"departure_timestamp"];
    
    //arrival_time
    NSInteger t2 = [Preferred_arrival_time timeIntervalSince1970];
    [result setValue:[NSString stringWithFormat:@"%.0ld", (long)t2 ] forKey:@"arrival_timestamp"];
    
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"hh:mma"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setLocale:locale];
    
    // Result Start Time
    if (Preferred_departure_time)
        [result setValue:[df stringFromDate: Preferred_departure_time] forKey:@"start_time"];
    else
        [result setValue:@"" forKey:@"start_time"];
    // Result End Time
    if (Preferred_arrival_time)
        [result setValue:[NSString stringWithFormat:@"-%@", [df stringFromDate: Preferred_arrival_time]] forKey:@"end_time"];
    else
        [result setValue:@"" forKey:@"end_time"];
    
    [df setDateFormat:@"MMM dd"];
    
    // Result Date
    if (Preferred_departure_time)
        [result setValue:[df stringFromDate: Preferred_departure_time] forKey:@"date"];
    else
        [result setValue:@"Walking" forKey:@"date"];
    
    float walking_time = 0.0;
    
    NSString *route_details = @"";
    
    NSMutableArray *resultForSaveItinerary = [[NSMutableArray alloc] initWithCapacity:10];
    
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    NSEnumerator *enmueratorsteps_array = [steps_array objectEnumerator];
    NSMutableDictionary *step;
    while (step = [enmueratorsteps_array nextObject]) {
        if (![route_details isEqualToString:@""]) {
            route_details = [route_details stringByAppendingString:@" >"];
        }
        
        if ([[step objectForKey:@"travel_mode"] isEqualToString:@"WALKING"]) {
            NSMutableDictionary *result2 = [[NSMutableDictionary alloc] initWithCapacity:2];
            
            float walkDistance = [[[step objectForKey:@"duration"] objectForKey:@"value"] floatValue];
            
            [result2 setValue:[NSNumber numberWithFloat:walkDistance ] forKey:@"actualWalkDistance"];
            [result2 setValue:[NSNumber numberWithInteger:0]  forKey:@"actual_departure_time"];
            [result2 setValue:[NSNumber numberWithInteger:0] forKey:@"actual_arrival_time"];
            [result2 setValue:@"WALKING" forKey:@"travel_mode"];
            [result2 setValue:[NSNumber numberWithInteger:0] forKey:@"totalSteps"];
            [resultForSaveItinerary addObject:result2];
            
            route_details = [route_details stringByAppendingString:@" \U0001F6B6"];
            
            walking_time = walking_time + [[[step objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60;
            
        } else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            NSMutableDictionary *result2 = [[NSMutableDictionary alloc] initWithCapacity:2];
            
            NSDate *departure_date1 = [formatter dateFromString:[[[step objectForKey:@"transit"] objectForKey:@"departure_time"] objectForKey:@"value"] ];
            [result2 setValue:[NSNumber numberWithInteger:[departure_date1 timeIntervalSince1970]]  forKey:@"actual_departure_time"];
            NSString *departure_stop_name = [[[step objectForKey:@"transit"] objectForKey:@"departure_stop"] objectForKey:@"name"];
            [result2 setValue:departure_stop_name forKey:@"departure_stop_name"];
            
            NSDate *arrival_date1 = [formatter dateFromString:[[[step objectForKey:@"transit"] objectForKey:@"arrival_time"] objectForKey:@"value"] ];
            [result2 setValue:[NSNumber numberWithInteger:[arrival_date1 timeIntervalSince1970]] forKey:@"actual_arrival_time"];
            NSString *arrival_stop_name = [[[step objectForKey:@"transit"] objectForKey:@"arrival_stop"] objectForKey:@"name"];
            [result2 setValue:arrival_stop_name forKey:@"arrival_stop_name"];
            
            [result2 setValue:@"TRANSIT" forKey:@"travel_mode"];
            [resultForSaveItinerary addObject:result2];
        }
    }
    
    
    [result setObject:resultForSaveItinerary forKey:@"resultForSaveItinerary"];
    NSMutableDictionary *result2 = [[NSMutableDictionary alloc] initWithCapacity:2];
    [result2 setValue:[NSNumber numberWithFloat:([[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60-walking_time )*2 ] forKey:@"mta_points"];
    [result2 setValue:[NSNumber numberWithFloat:([[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60-walking_time )*1 ] forKey:@"carbon_credits"];
    [result setObject:result2 forKey:@"incentives"];
    
    
    
    return result;
    
}


@end
