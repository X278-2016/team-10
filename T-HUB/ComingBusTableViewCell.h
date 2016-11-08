//
//  ComingBusTableViewCell.h
//  T-HUB
//
//  Created by Fangzhou Sun on 5/14/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ComingBusTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *uILabel_route_name;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_stop_name;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_time;

@end
