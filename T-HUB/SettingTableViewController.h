//
//  SettingTableViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 4/28/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingTableViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UISwitch *uiswitch_ServiceAlerts;
@property (strong, nonatomic) IBOutlet UISwitch *uiswitch_Navigations;
@property (strong, nonatomic) IBOutlet UITextField *uitextfield_busID;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_alertTime;
@property (strong, nonatomic) IBOutlet UISlider *uISlider_alertTime;
@property (strong, nonatomic) IBOutlet UISwitch *uISwitch_thubTimeBool;
@property (strong, nonatomic) IBOutlet UISwitch *uISwitch_demoMode;
- (IBAction)didTapForMoreInfo:(id)sender;

@property (weak, nonatomic) IBOutlet UIScrollView *uIScrollView_ack;
- (IBAction)didTapVideo:(id)sender;
- (IBAction)didTapSCOPE:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_currentVersion;


@end
