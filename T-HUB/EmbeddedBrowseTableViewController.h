//
//  EmbeddedBrowseTableViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 8/18/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmbeddedBrowseTableViewController : UITableViewController <UITableViewDelegate>

@property (nonatomic) NSInteger isNearbyBusesShown;
- (void)setIsNearbyBusesShownToInt:(int) i;
@end
