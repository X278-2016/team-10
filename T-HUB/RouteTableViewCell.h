//
//  RouteTableViewCell.h
//  T-HUB
//
//  Created by Fangzhou Sun on 4/26/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RouteTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *lbl_start_time;
@property (strong, nonatomic) IBOutlet UILabel *lbl_end_time;
@property (strong, nonatomic) IBOutlet UILabel *lbl_route_times;
@property (strong, nonatomic) IBOutlet UILabel *lbl_route_details;
@property (strong, nonatomic) IBOutlet UILabel *lbl_month;

@property (strong, nonatomic) IBOutlet UIButton *uibtn_prefer;
@property (weak, nonatomic) IBOutlet UIButton *uIButton_goNow;
@property (strong, nonatomic) IBOutlet UILabel *lbl_mtaPoints;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_expected_delay;
@end
