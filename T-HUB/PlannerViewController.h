//
//  PlannerViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 4/26/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Canvas.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>
#import "Calendar.h"

@interface PlannerViewController : UIViewController <GMSMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_Top;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_FromGo;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_Map;
@property (strong, nonatomic) IBOutlet UITextField *uitextfield_from;
@property (strong, nonatomic) IBOutlet UITextField *uitextfield_to;
@property (strong, nonatomic) IBOutlet UIButton *uibutton_search;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_timePicker;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_routes;
@property (strong, nonatomic) IBOutlet UITableView *uitableview_routes;

- (IBAction)btn_route:(id)sender;
- (IBAction)btn_search:(id)sender;

@property (strong, nonatomic) IBOutlet UIDatePicker *uidatepicker;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segment_whentoleave;


@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_Recurring;

- (IBAction)btn_recurring_no:(id)sender;
- (IBAction)btn_recurring_yes:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *uitextfield_days_recurring;

@property (strong, nonatomic) NSMutableDictionary *reschedule_route_dictionary;

@end
