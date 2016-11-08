//
//  QueryViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 10/7/15.
//  Copyright © 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Canvas.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>

@interface QueryViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, GMSMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet CSAnimationView *cSAnimationView_top;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAnimationView_content;

@property (weak, nonatomic) IBOutlet CSAnimationView *cSAnimationView_routePicker;
@property (weak, nonatomic) IBOutlet UIPickerView *uIPickerView_routePicker;
- (IBAction)didTapGoBack:(id)sender;
- (IBAction)didTapSelectRoute:(id)sender;

- (IBAction)didTapCancelInView:(id)sender;
- (IBAction)didTapDoneInView:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_topInfo;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAnimationView_topInfo;
@property (weak, nonatomic) IBOutlet UIView *uIView_busStopMarker;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_busStopMarker_expectedTime;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_busStopMarker_stopId;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAnimationView_previousAndNextTrips;
@property (weak, nonatomic) IBOutlet UIButton *uIButton_previousTrip;
- (IBAction)didTapPreviousTrip:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *uIButton_nextTrip;
- (IBAction)didTapNextTrip:(id)sender;

@end
