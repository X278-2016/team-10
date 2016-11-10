//
//  TripPlannerViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 5/11/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Canvas.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>

@interface TripPlannerViewController : UIViewController <GMSMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_base;
@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_locationsAndTime;

@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_plan_button;

@property (strong, nonatomic) IBOutlet UITextField *uITextField_from;
@property (strong, nonatomic) IBOutlet UITextField *uITextField_to;

@property (strong, nonatomic) IBOutlet UIButton *uIButton_leaveNow;
- (IBAction)didTapLeaveNow:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *uIButton_arriveAt;
- (IBAction)didTapArriveAt:(id)sender;

@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_datePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *uIDatePicker_datePicker;
- (IBAction)didTapDatePicker_cancel:(id)sender;
- (IBAction)didTapDatePicker_done:(id)sender;


- (IBAction)didTapGoPlanning:(id)sender;

@end
