//
//  ServiceAlertsViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 8/18/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServiceAlertsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *uITableView_serviceAlerts;
- (IBAction)didTapBack:(id)sender;

@end
