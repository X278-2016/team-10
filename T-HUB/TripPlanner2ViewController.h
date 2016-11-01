//
//  TripPlanner2ViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 5/12/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Canvas.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>

#import <ProtocolBuffers/ProtocolBuffers.h>

@interface TripPlanner2ViewController : UIViewController  <GMSMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_baseMap;
@property (strong, nonatomic) IBOutlet UITextField *uITextField_topSearchBar;
@property (strong, nonatomic) IBOutlet UITextField *uITextField_topSearchBar2;
@property (strong, nonatomic) IBOutlet UIButton *uIButton_depart;
@property (strong, nonatomic) IBOutlet UIButton *uIButton_arrive;
@property (strong, nonatomic) IBOutlet UIButton *uIButton_startFromHere;
@property (strong, nonatomic) IBOutlet UIButton *uIButton_EndAtHere;

@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_topSearchBar;
@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_commingBuses;
@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_setStartEnd;

- (IBAction)didTapDepartTime:(id)sender;
- (IBAction)didTapArriveTime:(id)sender;

- (IBAction)didTapStartHere:(id)sender;
- (IBAction)didTapEndHere:(id)sender;

@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_centerMarker;

@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_datePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *uIDatePicker_datePicker;
- (IBAction)didTapDatePicker_cancel:(id)sender;
- (IBAction)didTapDatePicker_done:(id)sender;

@property (strong, nonatomic) IBOutlet UIButton *uIButton_comming_buses;
- (IBAction)didTap_coming_buses:(id)sender;

@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_myLocation;
- (IBAction)didTapMyLocation:(id)sender;
@property (strong, nonatomic) IBOutlet UITableView *uITableView_comingBuses;

// Search History
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAV_searchHistory;
@property (weak, nonatomic) IBOutlet UITableView *uITableView_searchHistory;
- (IBAction)didTapHideSearchHistoryView:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_searchHistory_title;


@end
