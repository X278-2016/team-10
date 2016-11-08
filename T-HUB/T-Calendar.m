//
//  T-Calendar.m
//  T-HUB
//
//  Created by Fangzhou Sun on 5/5/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "T-Calendar.h"

@implementation T_Calendar

-(instancetype)initWithValues:(NSString *)Address_from Address_to:(NSString *)Address_to When_status:(NSInteger)When_status When_time:(NSInteger )When_time Scheduled_route_dic:(NSMutableDictionary *)Scheduled_route_dic {
    self = [super init];
    if (self) {
        // Set the documents directory path to the documentsDirectory property.
        self.Address_from = Address_from;
        self.Address_to = Address_to;
        self.When_status = When_status;
        self.When_time = When_time;
        self.Scheduled_route_dic = Scheduled_route_dic;;
    }
    return self;
}


@end
