//
//  BusAnnotationView.h
//  GCTC2
//
//  Created by Fangzhou Sun on 4/24/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BusAnnotationView : UIView

@property NSString *routeName;
@property double busDistance;


- (UIImage *)snapshot:(UIView *)view routeName:(NSString *)routeName busDistance:(double)busDistance;

@end
