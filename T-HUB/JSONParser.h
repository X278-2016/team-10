//
//  JSONParser.h
//  T-HUB
//
//  Created by Fangzhou Sun on 5/7/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONParser : NSObject

- (NSMutableDictionary *)getRouteDetails:(NSMutableDictionary *)route_dic;
- (NSMutableDictionary *)getRouteDetailsForDataCollection:(NSMutableDictionary *)route_dic;
- (NSMutableDictionary *)getRouteDetailsForDataCollection_actualTrip:(NSMutableDictionary *)route_dic;
@end
