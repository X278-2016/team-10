//
//  Calendar.m
//  T-HUB
//
//  Created by Fangzhou Sun on 4/27/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "Calendar.h"

@implementation Calendar

-(instancetype)initWithValues:(NSString *)Address_from Address_to:(NSString *)Address_to When_status:(NSInteger)When_status When_time:(NSInteger )When_time Scheduled_departure_time:(NSInteger )Scheduled_departure_time Scheduled_arrival_time:(NSInteger )Scheduled_arrival_time Scheduled_walking_time:(NSInteger )Scheduled_walking_time Scheduled_total_time:(NSInteger )Scheduled_total_time Scheduled_details:(NSString *)Scheduled_details Scheduled_dictionary:(NSMutableDictionary *)Scheduled_dictionary  Whole_dictionary:(NSMutableDictionary *)Whole_dictionary{
    self = [super init];
    if (self) {
        // Set the documents directory path to the documentsDirectory property.
        self.Address_from = Address_from;
        self.Address_to = Address_to;
        self.When_status = When_status;
        self.When_time = When_time;
        self.Scheduled_departure_time = Scheduled_departure_time;
        self.Scheduled_arrival_time = Scheduled_arrival_time;
        self.Scheduled_walking_time = Scheduled_walking_time;
        self.Scheduled_total_time = Scheduled_total_time;
        self.Scheduled_details = Scheduled_details;
        self.Scheduled_dictionary = [Scheduled_dictionary mutableCopy];
        self.Whole_dictionary = [Whole_dictionary mutableCopy];
    }
    return self;
}

@end
