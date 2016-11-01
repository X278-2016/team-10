//
//  Calendar.h
//  T-HUB
//
//  Created by Fangzhou Sun on 4/27/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Calendar : NSObject

@property (nonatomic, strong) NSString *Address_from;
@property (nonatomic, strong) NSString *Address_to;
@property (nonatomic, assign) NSInteger When_status;
@property (nonatomic, assign) NSInteger When_time;
@property (nonatomic, assign) NSInteger Scheduled_departure_time;
@property (nonatomic, assign) NSInteger Scheduled_arrival_time;
@property (nonatomic, assign) NSInteger Scheduled_walking_time;
@property (nonatomic, assign) NSInteger Scheduled_total_time;
@property (nonatomic, strong) NSString *Scheduled_details;
@property (nonatomic, strong) NSMutableDictionary *Scheduled_dictionary;
@property (nonatomic, strong) NSMutableDictionary *Whole_dictionary;

//@property (nonatomic, assign) NSInteger date;


-(instancetype)initWithValues:(NSString *)Address_from Address_to:(NSString *)Address_to When_status:(NSInteger)When_status When_time:(NSInteger )When_time Scheduled_departure_time:(NSInteger )Scheduled_departure_time Scheduled_arrival_time:(NSInteger )Scheduled_arrival_time Scheduled_walking_time:(NSInteger )Scheduled_walking_time Scheduled_total_time:(NSInteger )Scheduled_total_time Scheduled_details:(NSString *)Scheduled_details Scheduled_dictionary:(NSMutableDictionary *)Scheduled_dictionary Whole_dictionary:(NSMutableDictionary *)Whole_dictionary;

@end
