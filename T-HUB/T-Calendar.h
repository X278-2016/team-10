//
//  T-Calendar.h
//  T-HUB
//
//  Created by Fangzhou Sun on 5/5/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface T_Calendar : NSObject

@property (nonatomic, strong) NSString *Address_from;
@property (nonatomic, strong) NSString *Address_to;
@property (nonatomic, assign) NSInteger When_status;
@property (nonatomic, assign) NSInteger When_time;
@property (nonatomic, assign) NSMutableDictionary *Scheduled_route_dic;

//@property (nonatomic, assign) NSInteger date;


-(instancetype)initWithValues:(NSString *)Address_from Address_to:(NSString *)Address_to When_status:(NSInteger)When_status When_time:(NSInteger )When_time Scheduled_route_dic:(NSMutableDictionary *)Scheduled_route_dic;

@end
