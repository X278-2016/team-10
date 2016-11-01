//
//  SuggestedRoutesViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 5/11/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

/*
 This is the suggested route view controller
 This view provides the suggested transit routes to users after they tap the "Plan Your Trip" button in trip planner.
 */

#import <UIKit/UIKit.h>
#import <Canvas.h>

@interface SuggestedRoutesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>
- (IBAction)didTapGoBack:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *uitableview_routes;

@property (strong, nonatomic) NSMutableDictionary *route_dic;

@property (strong, nonatomic) NSMutableDictionary *scheduled_route_param;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_from;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_to;
@property (strong, nonatomic) NSString *address_from;
@property (strong, nonatomic) NSString *address_to;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_departTime;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_arrivalTime;

@property (weak, nonatomic) IBOutlet UILabel *uILabel_car_label1;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_car_label2;
@end
