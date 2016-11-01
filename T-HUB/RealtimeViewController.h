//
//  RealtimeViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 4/26/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Canvas.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>
#import "ScheduledTrip.h"

@interface RealtimeViewController : UIViewController <GMSMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_Map;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_Top;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_RealtimeLabel;
@property (strong, nonatomic) IBOutlet UILabel *lbl_realtimeLabel;
@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_RealtimeLabel2;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_realtimeLabel2;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_realtimeLabel2_1;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_realtimeLabel2_2;
@property (strong, nonatomic) IBOutlet UIButton *uIButton_scheduleOrRealtime;

@property (strong, nonatomic) IBOutlet UIView *uIView_map_base;

@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_GO;
@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_details;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nSLayoutConstraint_details_height;
- (IBAction)didTapGo:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_goTimer;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_calories;
@property (strong, nonatomic) IBOutlet UIButton *uIButton_Go;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_time_nextBus;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_text_nextBus;
@property (strong, nonatomic) IBOutlet UIButton *uIButton_next_segment;
- (IBAction)didTagNextSegment:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *uIButton_realtime_or_schedule;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAnimationView_browse;
- (IBAction)didTapBrowse:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *uIButton_browse;

@property (weak, nonatomic) IBOutlet CSAnimationView *cSAnimationView_tripInfo;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_tripInfo_from;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_tripInfo_to;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_tripInfo_time;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_tripInfo_details;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAnimationView_wantToTrackLocation;
- (IBAction)didTapTrackRealtimeLocation:(id)sender;
- (IBAction)didTapRoutes:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *uIButton_routes;
- (IBAction)didTapBrowseOK:(id)sender;

@property (strong, nonatomic) NSString *calendar_searchID;
@property (strong, nonatomic) NSMutableDictionary *calendar_route_dic_from_database;
@property (strong, nonatomic) NSString *calendar_ScheduledTrip_uuid;
@property (retain, nonatomic) NSString *ifMissedThenPopResetFlag;

- (IBAction)didTapDismissViewController:(id)sender;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAV_loadEarlierCheckpoint;
- (IBAction)didTap_loadEarlierCheckpoint_resume:(id)sender;
- (IBAction)didTap_loadEarlierCheckpoint_reset:(id)sender;


@end
