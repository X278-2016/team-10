//
//  CommonAPI.h
//  T-HUB
//
//  Created by Fangzhou Sun on 10/13/15.
//  Copyright © 2015 Fangzhou Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CommonAPI : NSObject

+ (NSMutableArray *)polylineWithEncodedString:(NSString *)encodedString;

@end
