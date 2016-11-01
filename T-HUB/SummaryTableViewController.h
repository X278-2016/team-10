//
//  SummaryTableViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 7/31/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SummaryTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UILabel *uILabel_time_taking_bus;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_time_walking;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_calories_burned;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_gas_saving;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_transit_points;

@end
