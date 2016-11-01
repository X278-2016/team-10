//
//  StatusView.h
//  MyDay
//
//  Created by Fangzhou Sun on 11/1/14.
//  Copyright (c) 2014 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatusView : UIView

@property UILabel *label;

- (id)initWithText:(NSString *)text delayToHide:(float)delayToHide iconIndex:(int)iconIndex;
- (void)rePostion;
- (void)setText:(NSString *)text;
@end
