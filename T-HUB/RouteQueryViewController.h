//
//  RouteQueryViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 12/2/15.
//  Copyright © 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>

@interface RouteQueryViewController : UIViewController <UIScrollViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, GMSMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, GMSMapViewDelegate>
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAV_topView;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAV_directionPickerView;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAV_mapView;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAV_routeSelectionView;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAV_tripDetailsView;
@property (weak, nonatomic) IBOutlet UIPickerView *uIPickerView_routes;
@property (weak, nonatomic) IBOutlet UITableView *uITableView_tripDetails;
- (IBAction)didTapRouteSelectionCancel:(id)sender;
- (IBAction)didTapRouteSelectionDone:(id)sender;

- (IBAction)didTapSelectRoute:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *uIView_aKPicker;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_topInfo;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_stopName;

@property (weak, nonatomic) IBOutlet UIView *uIView_busStopMarker;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_busStopMarker_expectedTime;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_busStopMarker_stopId;
@property (weak, nonatomic) IBOutlet UIImageView *uIImageView_stopIcon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nSLayoutConstraint_cSAnimtionView_headsignPicker_height;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nSLayoutConstraint_cSAnimtionView_tripDetails_height;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAV_selectedStopDetail;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_selectedStop_detail;
- (IBAction)didTapHideSelectedStopDetail:(id)sender;

@end
