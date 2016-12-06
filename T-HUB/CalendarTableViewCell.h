//
//  CalendarTableViewCell.h
//  T-HUB
//
//  Created by Fangzhou Sun on 4/27/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CalendarTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *lbl_start_time;
@property (strong, nonatomic) IBOutlet UILabel *lbl_end_time;
@property (strong, nonatomic) IBOutlet UILabel *lbl_route_times;
@property (strong, nonatomic) IBOutlet UILabel *lbl_route_details;
@property (strong, nonatomic) IBOutlet UILabel *lbl_from;
@property (strong, nonatomic) IBOutlet UILabel *lbl_to;
@property (strong, nonatomic) IBOutlet UILabel *lbl_depart_arrive_time;
@property (weak, nonatomic) IBOutlet UIButton *uIButton_serviceAlert;

@property (strong, nonatomic) IBOutlet UIButton *uibtn_otherroutes;
@property (strong, nonatomic) IBOutlet UIButton *uibtn_simulate;
@property (strong, nonatomic) IBOutlet UIButton *uibtn_scheduleRoute;
@property (strong, nonatomic) IBOutlet UIButton *uibtn_setRecurring;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_titleForScheduledRoute;
// share button
@property (strong, nonatomic) IBOutlet UIButton *uibtn_shareRoute;

@end
