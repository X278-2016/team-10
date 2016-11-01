//
//  RealtimeViewController.m
//  GCTC2
//
//  Created by Fangzhou Sun on 4/14/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

/*
 This is the navigation view controller
 Step-by-step navigation will be provided by this view
 */

#import "RealtimeViewController.h"
#import "AppDelegate.h"
#import "ColorConstants.h"
#import "Calendar.h"
#import "AFNetworking.h"
#import "BusAnnotationView.h"
#import "MyBusAnnotationView.h"
#import "EmbeddedBrowseTableViewController.h"
#import "QueryViewController.h"

#import <ProtocolBuffers/ProtocolBuffers.h>
#import "GtfsRealtime.pb.h"

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

#import "JSONParser.h"
#import "CommonAPI.h"

enum ViewStatus {
    ViewStatus_mapview,
    ViewStatus_mapview_tripStarted
};

@interface RealtimeViewController() {
    AppDelegate *appDelegate;
    //    Calendar *localCalendar;
    NSTimer *realtimeUpdateTimer;
    NSTimer *goTimer;
    NSTimeInterval goTimer_start;
    NSTimeInterval lastTimeSinceMapIdleAtCameraPosition;
    
    CLLocationCoordinate2D myLastLocation;
    
    NSTimer *browseTimer;
    EmbeddedBrowseTableViewController *embeddedBrowseTableViewController;
    NSMutableArray *nearbyBusMarkers;
    
    //    NSMutableDictionary *leg_array;
    //    NSMutableDictionary *bounds_dic;
    
    NSMutableDictionary *route_dic_from_database;
    
    NSMutableDictionary *selectedRouteDic;
    
    NSMutableArray *busMarkers;
    
    NSString *trip_id_;
    
    NSString *route_id_;
    NSString *trip_headsign_;
    NSString *sch_arr_dt_timestamp_;
    NSString *stop_id_;
    
    enum ViewStatus viewStatus;
    
    // Status variable in the trip
    int trip_status_index;
    
    NSDictionary *stepInfoToDisplay_dic;
    
    NSString *old_str;
    
    float fakeLat;
    float fakeLon;
    BOOL fakeLocationFlag;
    
    float actualDistance;
    NSMutableArray *array_actualTrip;
    NSTimeInterval startTime_eachSection;
    
    // Save statistic every 5 seconds;
    float actualDistance_every5seconds;
    NSTimeInterval startTime_eachSection_every5seconds;
    
    NSString *searchID;
    JSONParser *jsonParser;
    
    NSMutableDictionary *mapForTripIDAndRouteID;
    NSManagedObjectContext* objectContext;
    
    NSTimer *nSTimer_updateSummaryStatistics;
}

@property (strong, nonatomic) GMSMapView *mapView;

@property (nonatomic, strong) CLLocationManager *locationManager;

//@property (nonatomic, strong) CMPedometer *pedometer;

@property (nonatomic, strong) NSOperationQueue *myQueue;

@end

@implementation RealtimeViewController

@synthesize ifMissedThenPopResetFlag;

- (void)viewDidLoad
{
    [self startAnimationToFadeEverything];
    
    [super viewDidLoad];
    self.ifMissedThenPopResetFlag = @"YES";
    
    viewStatus = ViewStatus_mapview;
    
    objectContext = [CoreDataHelper managedObjectContext];
    
    jsonParser = [[JSONParser alloc] init];
    
    // AppDelegate
    appDelegate = ((AppDelegate*)[[UIApplication sharedApplication]delegate]);
    
    self.myQueue = [[NSOperationQueue alloc] init];
    
    //    browseTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(getNearbyBusesAndShowOnMap) userInfo:nil repeats:YES];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(getUpdatedLocationAndDrawRouteOnMap)
//                                                 name:@"updateLocationToServer"
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didTapBrowse:)
                                                 name:@"tapNearbyBusesFromTheView"
                                               object:nil];
    
    [self.cSAnimationView_wantToTrackLocation setHidden:YES];
    
    mapForTripIDAndRouteID = [[NSMutableDictionary alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self ifCheckpointThenPopup];
    
    [self UpdateViewByViewStatus];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    
    fakeLat = 36.165546;
    fakeLon = -86.777033;
    fakeLocationFlag = NO;
    if ([defaults objectForKey:@"demoMode"])
        if ([[defaults objectForKey:@"demoMode"] boolValue])
            fakeLocationFlag = YES;
    
    [self initMap];
    
    [self.myQueue addOperationWithBlock: ^ {
        
        // Update UI on the main thread.
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
            BOOL flag = [self loadCalendarsFromDatabase];
            NSLog(@"flag:%d", flag);
            if (!flag) {
                self.cSAnimationView_GO.hidden=YES;
                self.cSAnimationView_wantToTrackLocation.hidden = YES;
                if (viewStatus==ViewStatus_mapview_tripStarted)
                    [self didTapGo:nil];
                self.cSAnimationView_RealtimeLabel2.hidden = YES;
                
                //
                self.cSAnimationView_tripInfo.hidden=YES;
            } else {
                self.cSAnimationView_GO.hidden=NO;
                [self showRoute];
                
                //
                self.cSAnimationView_tripInfo.hidden=NO;
                [self showcSAnimationView_tripInfo];
                
                NSMutableDictionary *result2 = [jsonParser getRouteDetails:route_dic_from_database];
                NSLog(@"557:%@", result2);
                
                self.uILabel_tripInfo_from.text = [NSString stringWithFormat:@"From: %@", [result2 objectForKey:@"start_address"]];
                self.uILabel_tripInfo_to.text = [NSString stringWithFormat:@"To: %@", [result2 objectForKey:@"end_address"]];
                self.uILabel_tripInfo_time.text = [NSString stringWithFormat:@"%@ %@",[result2 objectForKey:@"start_time"], [result2 objectForKey:@"end_time"]];
                
                self.uILabel_tripInfo_details.text = [result2 objectForKey:@"route_details"];
                self.uILabel_tripInfo_details.text = @"";
                NSMutableArray *route_details_array = [result2 objectForKey:@"route_details_array"];
                float length_route_details = 0.0;
                CGRect screenBound = [[UIScreen mainScreen] bounds];
                
                for (UIView *subView in self.cSAnimationView_tripInfo.subviews) {
                    if (subView.tag ==1) {
                        [subView removeFromSuperview];
                    }
                }
                
                UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0, 90, 0, screenBound.size.height)];
                aView.tag=1;
                for (NSString *detail in route_details_array) {
                    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(length_route_details, 0, 0, 0)];
                    if ([detail rangeOfString:@"UNICODE"].location != NSNotFound) {
                        aLabel.text = [detail substringFromIndex:7];
                    } else {
                        aLabel.text = detail;
                    }
                    aLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:13];
                    aLabel.numberOfLines=0;
                    [aLabel sizeToFit];
                    if ([detail rangeOfString:@"UNICODE"].location != NSNotFound) {
                        aLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
                    }
                    length_route_details +=aLabel.frame.size.width;
                    [aView addSubview:aLabel];
                }
                
                float indentation = (screenBound.size.width-length_route_details)/2;
                [aView setFrame:CGRectMake(aView.frame.origin.x+indentation, aView.frame.origin.y, aView.frame.size.width, aView.frame.size.height)];
                [self.cSAnimationView_tripInfo addSubview:aView];
            }
            
            [self updateMapCenterLocation];
        }];
        
    }];
    
    
    [[self.uIButton_next_segment layer] setCornerRadius:5.0f];
    
    [[self.uIButton_next_segment layer] setMasksToBounds:YES];
    
    [[self.uIButton_next_segment layer] setBorderWidth:1.0f];
    [[self.uIButton_next_segment layer] setBorderColor:DefaultGreen.CGColor];
    [self.uIButton_next_segment setTitle:@"\U00002713" forState:UIControlStateNormal];
    
    //    [self getAlertUpdates];
    
}

- (void)ifCheckpointThenPopup {
    NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"uuid==%@", self.calendar_ScheduledTrip_uuid ] inManagedObjectContext:objectContext];
    if ([items count]>0) {
        ScheduledTrip *scheduledTrip = [items firstObject];
//        NSLog(@"TMP:::2:::%d", [scheduledTrip.checkpoint intValue]);
        if ([scheduledTrip.checkpoint intValue]>=0) {
            self.cSAV_loadEarlierCheckpoint.hidden = NO;
            self.cSAV_loadEarlierCheckpoint.type = CSAnimationTypeBounceUp;
            self.cSAV_loadEarlierCheckpoint.duration = 0.3;
            self.cSAV_loadEarlierCheckpoint.delay = 0.0;
            [self.cSAV_loadEarlierCheckpoint startCanvasAnimation];
            self.uIButton_Go.enabled = NO;
            [self.view bringSubviewToFront:self.cSAV_loadEarlierCheckpoint];
            self.cSAV_loadEarlierCheckpoint.alpha = 1;
        } else {
            self.cSAV_loadEarlierCheckpoint.hidden = YES;
            self.uIButton_Go.enabled = YES;
            self.cSAV_loadEarlierCheckpoint.alpha = 0;
        }
    }
}

-(void)showcSAnimationView_tripInfo {
    self.cSAnimationView_tripInfo.type = CSAnimationTypeBounceLeft;
    self.cSAnimationView_tripInfo.duration = 0.3;
    self.cSAnimationView_tripInfo.delay = 0.6;
    [self.cSAnimationView_tripInfo startCanvasAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self startAnimationToFadeEverything];
    [self.myQueue cancelAllOperations];
    [goTimer invalidate];
    goTimer=nil;
}

-(BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    return YES;
}

-(void)getAlertUpdates {
    NSURL *URL=[NSURL URLWithString:@"https://129.59.105.175/static/Data/Feed/tripupdates.pb"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"thubTimeBool"]) {
        if ([[defaults objectForKey:@"thubTimeBool"] boolValue])
            URL=[NSURL URLWithString:@"https://129.59.105.175/static/Data/Feed/Augmented/tripupdates.pb"];
        else
            URL=[NSURL URLWithString:@"https://129.59.105.175/static/Data/Feed/tripupdates.pb"];
    }
    
    URL=[NSURL URLWithString:@"http://transitdata.nashvillemta.org/TMGTFSRealTimeWebService/alert/alerts.pb"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    //    NSString *fileName = [URL lastPathComponent];
    
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        // here we must create NSData object with received data...
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
        NSLog(@"alertUpdates.feedMessage.entity: %@ ", feedMessage.entity);
        for (FeedEntity *feedEntity in feedMessage.entity) {
            NSLog(@"headerText%@", feedEntity.alert.headerText);
        }
        
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
    
}

-(void)UpdateViewByTripStatusIndex {
    NSArray *step_array = [[[route_dic_from_database objectForKey:@"legs"] objectAtIndex:0] objectForKey:@"steps"];
    NSDictionary *step = [step_array objectAtIndex: trip_status_index];
    
    if ([[step objectForKey:@"travel_mode"] isEqualToString:@"WALKING"]) {
        self.lbl_realtimeLabel.text = [step objectForKey:@"instructions"];
        
        if ([step_array count]>trip_status_index+1) {
            [self.myQueue addOperationWithBlock: ^ {
                
//                stepInfoToDisplay_dic = [appDelegate.dbManager getTripInformationFromRouteDictionary:route_dic_from_database step_index:(trip_status_index+1)];
                stepInfoToDisplay_dic = [appDelegate.dbManager getTripInformation_new:route_dic_from_database step_index:(trip_status_index+1)];
//                                NSLog(@"TEST600::: getTripInformationFromRouteDictionary::: stepInfoToDisplay_dic::: %@", stepInfoToDisplay_dic);
                [stepInfoToDisplay_dic setValue: [NSNumber numberWithInt:0] forKey:@"start_stop_timestamp_realtime"];
                [stepInfoToDisplay_dic setValue: [NSNumber numberWithInt:0] forKey:@"end_stop_timestamp_realtime"];
                
                // Update UI on the main thread.
                [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                    self.cSAnimationView_RealtimeLabel2.hidden = NO;
                    //                    self.cSAnimationView_RealtimeLabel2.alpha=0.8;
                    self.cSAnimationView_RealtimeLabel2.type = CSAnimationTypeBounceLeft;
                    self.cSAnimationView_RealtimeLabel2.duration = 0.3;
                    self.cSAnimationView_RealtimeLabel2.delay = 0.75;
                    [self.cSAnimationView_RealtimeLabel2 startCanvasAnimation];
                }];
            }];
            
        } else {
            //            self.uILabel_text_nextBus.text = @"Towards";
            //            self.uILabel_time_nextBus.text = @"Destination";
            self.cSAnimationView_RealtimeLabel2.hidden = NO;
            //            self.cSAnimationView_RealtimeLabel2.alpha=0.8;
            self.cSAnimationView_RealtimeLabel2.type = CSAnimationTypeBounceLeft;
            self.cSAnimationView_RealtimeLabel2.duration = 0.3;
            self.cSAnimationView_RealtimeLabel2.delay = 0.75;
            [self.cSAnimationView_RealtimeLabel2 startCanvasAnimation];
            
            self.uILabel_realtimeLabel2_1.text = @"Approaching destination";
            
        }
        
    } else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
        self.lbl_realtimeLabel.text = [step objectForKey:@"instructions"];
        
        [self.myQueue addOperationWithBlock: ^ {
            
//            stepInfoToDisplay_dic = [appDelegate.dbManager getTripInformationFromRouteDictionary:route_dic_from_database step_index:(trip_status_index)];
            stepInfoToDisplay_dic = [appDelegate.dbManager getTripInformation_new:route_dic_from_database step_index:(trip_status_index)];
            [stepInfoToDisplay_dic setValue: [NSNumber numberWithInt:0] forKey:@"start_stop_timestamp_realtime"];
            [stepInfoToDisplay_dic setValue: [NSNumber numberWithInt:0] forKey:@"end_stop_timestamp_realtime"];
//            NSLog(@"UpdateViewByTripStatusIndex:%@", stepInfoToDisplay_dic);
            
            // Update UI on the main thread.
            [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
                self.cSAnimationView_RealtimeLabel2.hidden = NO;
                //                self.cSAnimationView_RealtimeLabel2.alpha=0.8;
                self.cSAnimationView_RealtimeLabel2.type = CSAnimationTypeBounceLeft;
                self.cSAnimationView_RealtimeLabel2.duration = 0.3;
                self.cSAnimationView_RealtimeLabel2.delay = 0.75;
                [self.cSAnimationView_RealtimeLabel2 startCanvasAnimation];
            }];
        }];
    }
}

- (void)UpdateViewByViewStatus {
    
    switch (viewStatus) {
        case ViewStatus_mapview: {
            trip_status_index = 0;
            self.nSLayoutConstraint_details_height.constant = 0;
            
            self.CSAnimationView_RealtimeLabel.hidden = YES;
            self.cSAnimationView_RealtimeLabel2.hidden = YES;
            self.cSAnimationView_RealtimeLabel2.alpha = 0;
            
            self.CSAnimationView_Top.alpha=1;
            self.CSAnimationView_Map.alpha=1;
            
            self.CSAnimationView_Top.type = CSAnimationTypeSlideDown;
            self.CSAnimationView_Top.duration = 0.3;
            self.CSAnimationView_Top.delay = 0.0;
            [self.CSAnimationView_Top startCanvasAnimation];
            
            self.CSAnimationView_Map.type = CSAnimationTypeFadeIn;
            self.CSAnimationView_Map.duration = 0.3;
            self.CSAnimationView_Map.delay = 0.0;
            [self.CSAnimationView_Map startCanvasAnimation];
            
            self.cSAnimationView_browse.type = CSAnimationTypePop;
            self.cSAnimationView_browse.duration = 0.3;
            self.cSAnimationView_browse.delay = 0.0;
            self.cSAnimationView_browse.hidden = YES;
            
            self.uIButton_browse.hidden = NO;
            self.uIButton_routes.hidden = NO;
            break;
        }
        case ViewStatus_mapview_tripStarted: {
            self.nSLayoutConstraint_details_height.constant = 0;
            
            self.CSAnimationView_RealtimeLabel.hidden = NO;
            self.cSAnimationView_RealtimeLabel2.hidden = YES;
            self.cSAnimationView_RealtimeLabel2.alpha = 0.8;
            
            self.CSAnimationView_RealtimeLabel.alpha=0.8;
            self.CSAnimationView_RealtimeLabel.type = CSAnimationTypeSlideLeft;
            self.CSAnimationView_RealtimeLabel.duration = 0.3;
            self.CSAnimationView_RealtimeLabel.delay = 0.6;
            [self.CSAnimationView_RealtimeLabel startCanvasAnimation];
            
            self.cSAnimationView_browse.hidden = true;
            self.uIButton_browse.hidden = YES;
            self.uIButton_routes.hidden = YES;
            [embeddedBrowseTableViewController setIsNearbyBusesShown:0];
            //            [self getNearbyBusesAndShowOnMap];
            
            [self UpdateViewByTripStatusIndex];
            
        }
        default:
            break;
    }
    
}

- (void)initMap {
    
    [self getCurrentLocation];
    
    if(self.mapView) {
        [self.mapView clear];
        [self.mapView removeFromSuperview];
    }
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.locationManager.location.coordinate.latitude longitude:self.locationManager.location.coordinate.longitude zoom:12];
    self.mapView = [GMSMapView mapWithFrame:self.uIView_map_base.bounds camera:camera];
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    self.mapView.indoorEnabled = NO;
    //    [self.CSAnimationView_Map addSubview:self.mapView];
    [self.uIView_map_base addSubview:self.mapView];
    
    if (fakeLocationFlag) {
        CLLocationCoordinate2D center;
        center.latitude = fakeLat;
        center.longitude = fakeLon;
        
        [self.mapView animateToLocation:center];
    }
}

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    if (gesture && goTimer) {
        [self.cSAnimationView_wantToTrackLocation setHidden:NO];
        //        self.cSAnimationView_wantToTrackLocation.alpha = 0.0;
        //        self.cSAnimationView_wantToTrackLocation.type = CSAnimationTypeFadeIn;
        //        self.cSAnimationView_wantToTrackLocation.duration = 1.0;
        //        self.cSAnimationView_wantToTrackLocation.delay = 4.3;
        //        [self.cSAnimationView_wantToTrackLocation startCanvasAnimation];
        self.cSAnimationView_wantToTrackLocation.alpha = 0.8;
    }
}

-(void)getCurrentLocation {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
}

-(void)getTripUpdate {
    
    
    NSURL *URL=[NSURL URLWithString:@"https://129.59.105.175/static/Data/Feed/tripupdates.pb"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"thubTimeBool"]) {
        if ([[defaults objectForKey:@"thubTimeBool"] boolValue])
            URL=[NSURL URLWithString:@"https://129.59.105.175/static/Data/Feed/Augmented/tripupdates.pb"];
        else
            URL=[NSURL URLWithString:@"https://129.59.105.175/static/Data/Feed/tripupdates.pb"];
    }
    
    //    URL=[NSURL URLWithString:@"https://129.59.105.175/static/Data/Feed/Augmented/tripupdates.pb"];
    URL=[NSURL URLWithString:@"http://transitdata.nashvillemta.org/TMGTFSRealTimeWebService/tripupdate/tripupdates.pb"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
//                NSLog(@"213feedMessage.entity: %@ ", feedMessage.entity);
        long start_stop_timestamp = 0;
        long end_stop_timestamp = 0;
        NSString *trip_id = @"";
        for (FeedEntity *feedEntity in feedMessage.entity) {
//            NSLog(@"913:%@", feedEntity);
//            NSLog(@"914:%@, %@", [stepInfoToDisplay_dic objectForKey:@"departure_stop_id"], [stepInfoToDisplay_dic objectForKey:@"arrival_stop_id"]);
            
            long tmp_start_stop_timestamp = 0;
            long tmp_end_stop_timestamp = 0;
            for (TripUpdateStopTimeUpdate *tripUpdateStopTimeUpdate in feedEntity.tripUpdate.stopTimeUpdate) {
//                NSLog(@"915:%@", tripUpdateStopTimeUpdate.stopId);
                if ([tripUpdateStopTimeUpdate.stopId isEqualToString:[stepInfoToDisplay_dic objectForKey:@"departure_stop_id"]])
                    tmp_start_stop_timestamp = tripUpdateStopTimeUpdate.departure.time;
                if ([tripUpdateStopTimeUpdate.stopId isEqualToString:[stepInfoToDisplay_dic objectForKey:@"arrival_stop_id"]])
                    tmp_end_stop_timestamp = tripUpdateStopTimeUpdate.departure.time;
            }
        
//            NSLog(@"916:%ld, %ld", tmp_start_stop_timestamp, tmp_end_stop_timestamp);
            
            if (tmp_start_stop_timestamp>0 && tmp_end_stop_timestamp>tmp_start_stop_timestamp && tmp_start_stop_timestamp>=[[stepInfoToDisplay_dic objectForKey:@"start_stop_timestamp"] longValue]) {
                if (start_stop_timestamp==0 || tmp_start_stop_timestamp<start_stop_timestamp) {
                    start_stop_timestamp =tmp_start_stop_timestamp;
                    end_stop_timestamp = tmp_end_stop_timestamp;
                    trip_id = feedEntity.tripUpdate.trip.tripId;
                }
            }
            
        }
        if (start_stop_timestamp>0) {
            [stepInfoToDisplay_dic setValue: [NSNumber numberWithLongLong:start_stop_timestamp] forKey:@"start_stop_timestamp_realtime"];
            [stepInfoToDisplay_dic setValue: [NSNumber numberWithLongLong:end_stop_timestamp] forKey:@"end_stop_timestamp_realtime"];
            [stepInfoToDisplay_dic setValue: trip_id forKey:@"trip_id"];
//            NSLog(@"906stepInfoToDisplay_dic: %@ ", stepInfoToDisplay_dic);
        }
        NSLog(@"906stepInfoToDisplay_dic: %@ ", stepInfoToDisplay_dic);
                
            
//            
//            if ([feedEntity.tripUpdate.trip.tripId isEqualToString:[NSString stringWithFormat:@"%@",[stepInfoToDisplay_dic objectForKey:@"trip_id"]]]) {
//                for (TripUpdateStopTimeUpdate *tripUpdateStopTimeUpdate in feedEntity.tripUpdate.stopTimeUpdate) {
//                    
//                    if (tripUpdateStopTimeUpdate.stopSequence == [[stepInfoToDisplay_dic objectForKey:@"start_stop_sequence"] intValue]) {
//                        [stepInfoToDisplay_dic setValue: [NSNumber numberWithLongLong:tripUpdateStopTimeUpdate.departure.time] forKey:@"start_stop_timestamp_realtime"];
//                        
//                    }
//                    if (tripUpdateStopTimeUpdate.stopSequence == [[stepInfoToDisplay_dic objectForKey:@"end_stop_sequence"] intValue]) {
//                        [stepInfoToDisplay_dic setValue: [NSNumber numberWithLongLong:tripUpdateStopTimeUpdate.departure.time] forKey:@"end_stop_timestamp_realtime"];
//
//                    }
//                    
//                }
//                
//            }
//        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
}


-(void)getVehiclePositionsUpdate {
    
    if (busMarkers==nil)
        busMarkers = [[NSMutableArray alloc] init];
    
    NSEnumerator *enmueratorMarker = [busMarkers objectEnumerator];
    GMSMarker *oneMarker;
    while (oneMarker = [enmueratorMarker nextObject]) {
        oneMarker.map = nil;
    }
    busMarkers = [[NSMutableArray alloc] init];
    
    //    nearbyBuses = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    NSURL *URL = [NSURL URLWithString:@"http://transitdata.nashvillemta.org/TMGTFSRealTimeWebService/vehicle/vehiclepositions.pb"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    //    NSString *fileName = [URL lastPathComponent];
    
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // here we must create NSData object with received data...
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
//                        NSLog(@"feedMessage.entity: %@ ", feedMessage.entity);
        for (FeedEntity *feedEntity in feedMessage.entity) {
//                        NSLog(@"TEST::: getVehiclePositionsUpdate::: stepInfoToDisplay_dic::: %@", stepInfoToDisplay_dic);
//                        NSLog(@"TEST::: getVehiclePositionsUpdate::: feedEntity::: %@",feedEntity);
            if ([feedEntity.vehicle.trip.tripId isEqualToString:[NSString stringWithFormat:@"%@",[stepInfoToDisplay_dic objectForKey:@"trip_id"]]]) {
                
                CLLocationCoordinate2D bus_position = CLLocationCoordinate2DMake(feedEntity.vehicle.position.latitude, feedEntity.vehicle.position.longitude);
                GMSMarker *bus_marker = [GMSMarker markerWithPosition:bus_position];
                
                bus_marker.icon = [UIImage imageNamed:@"bus_marker_002@2x.png"];
                if (stepInfoToDisplay_dic && [stepInfoToDisplay_dic objectForKey:@"route_id"])
                    bus_marker.title = [stepInfoToDisplay_dic objectForKey:@"route_id"];
                bus_marker.map = self.mapView;
                [self.mapView setSelectedMarker:bus_marker];
                
                [busMarkers addObject:bus_marker];
                
            }
        }
        
        NSEnumerator *enmueratorMarker = [busMarkers objectEnumerator];
        GMSMarker *oneMarker;
        enmueratorMarker = [busMarkers objectEnumerator];
        while (oneMarker = [enmueratorMarker nextObject]) {
            oneMarker.map = self.mapView;
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
}




- (BOOL)loadCalendarsFromDatabase {
    if (self.calendar_searchID && self.calendar_route_dic_from_database) {
        searchID = self.calendar_searchID;
        route_dic_from_database = self.calendar_route_dic_from_database;
        return true;
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
        return false;
    }
}

- (void)showRoute {
    [self.mapView clear];
    
    BOOL flag = false;
    if(route_dic_from_database)
        if ([route_dic_from_database isKindOfClass:[NSMutableDictionary class]] || [route_dic_from_database isKindOfClass:[NSDictionary class]])
            if ([route_dic_from_database objectForKey:@"legs"] && [route_dic_from_database objectForKey:@"bounds"])
                flag=true;
    if (!flag)
        return;
    
    self.cSAnimationView_GO.hidden=NO;
    
    NSMutableDictionary *leg_array = [[route_dic_from_database objectForKey:@"legs"] objectAtIndex:0];
    NSMutableDictionary *bounds_dic = [route_dic_from_database objectForKey:@"bounds"];
    
    NSMutableArray *colorArray = [[NSMutableArray alloc] init];
    [colorArray addObject:[UIColor colorWithRed:40/255.0 green:171/255.0 blue:227/255.0 alpha:1]];
    [colorArray addObject:[UIColor colorWithRed:31/255.0 green:218/255.0 blue:154/255.0 alpha:1]];
    
    NSString *overview_polyline = [route_dic_from_database objectForKey:@"overview_polyline"];
    NSArray *coordArray = [CommonAPI polylineWithEncodedString:overview_polyline];
    
    int colorIndex = 0;
    
    // Markers
    GMSMarker *tomarker =  [[GMSMarker alloc] init];
    tomarker.map = self.mapView;
    tomarker.icon = [UIImage imageNamed:@"redmarker@2x.png"];
    //    tomarker.position = CLLocationCoordinate2DMake([[[[leg_array objectForKey:@"end_location"] allValues] objectAtIndex:0] floatValue],[[[[leg_array objectForKey:@"end_location"] allValues] objectAtIndex:1] floatValue]);
    tomarker.position = [((CLLocation *)coordArray.lastObject) coordinate];
    
    // Markers
    GMSMarker *frommarker =  [[GMSMarker alloc] init];
    frommarker.map = self.mapView;
    frommarker.icon = [UIImage imageNamed:@"greenmarker@2x.png"];
    //    frommarker.position = CLLocationCoordinate2DMake([[[[leg_array objectForKey:@"start_location"] allValues] objectAtIndex:0] floatValue],[[[[leg_array objectForKey:@"start_location"] allValues] objectAtIndex:1] floatValue]);
    frommarker.position = [((CLLocation *)coordArray.firstObject) coordinate];
    
    
    
    double lat=[[bounds_dic objectForKey:@"north"] doubleValue];
    double lon=[[bounds_dic objectForKey:@"east"] doubleValue];
    if (lat<lon) {
        double t = lat;
        lat=lon;
        lon=t;
    }
    
    CLLocationCoordinate2D coordinateSouthWest = CLLocationCoordinate2DMake(
                                                                            lat,
                                                                            lon
                                                                            );
    
    lat=[[bounds_dic objectForKey:@"south"] doubleValue];
    lon=[[bounds_dic objectForKey:@"west"] doubleValue];
    if (lat<lon) {
        double t = lat;
        lat=lon;
        lon=t;
    }
    
    CLLocationCoordinate2D coordinateNorthEast = CLLocationCoordinate2DMake(
                                                                            lat,
                                                                            lon
                                                                            );
    
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:coordinateSouthWest coordinate:coordinateNorthEast];
    [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds]];
    
    //    NSLog(@"Test742: %@", [[[bounds_dic allValues] objectAtIndex:0] allValues], [[[bounds_dic allValues] objectAtIndex:1] allValues]);
    //    NSLog(@"Test734: %f \n %f", coordinateSouthWest.latitude, coordinateSouthWest.longitude);
    
    GMSCameraPosition *camera = [self.mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(35, 35, 45+35, 35)];
    [self.mapView animateToCameraPosition:camera];
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    NSEnumerator *enmueratorsteps_array = [steps_array objectEnumerator];
    NSMutableDictionary *step;
    while (step = [enmueratorsteps_array nextObject]) {
        
        if ([[step objectForKey:@"travel_mode"] isEqualToString:@"WALKING"]) {
            NSMutableArray *pathArray = [step objectForKey:@"path"];
            NSEnumerator *enmueratorpathArray = [pathArray objectEnumerator];
            NSMutableDictionary *onepath;
            
            GMSMutablePath *path = [GMSMutablePath path];
            while (onepath = [enmueratorpathArray nextObject]) {
                [path addCoordinate:CLLocationCoordinate2DMake([[onepath objectForKey:@"lat"] doubleValue], [[onepath objectForKey:@"lng"] doubleValue])];
            }
//            NSArray *pathArray = [CommonAPI polylineWithEncodedString: [[step objectForKey:@"polyline"] objectForKey:@"points"]];
//            NSEnumerator *enmueratorpathArray = [pathArray objectEnumerator];
//            CLLocation *oneLocation;
//            
//            GMSMutablePath *path = [GMSMutablePath path];
//            while (oneLocation = [enmueratorpathArray nextObject]) {
//                [path addCoordinate:[oneLocation coordinate]];
//                //                    [path addCoordinate:CLLocationCoordinate2DMake([[[onepath allValues] objectAtIndex:0] doubleValue], [[[onepath allValues] objectAtIndex:1] doubleValue])];
//            }
            
            GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
            
            polyline.strokeColor = [UIColor blackColor];
            polyline.strokeWidth = 6.f;
            polyline.geodesic = YES;
            NSArray *styles = @[[GMSStrokeStyle solidColor:[UIColor whiteColor]],
                                [GMSStrokeStyle solidColor:[UIColor blackColor]]];
            NSArray *lengths = @[@20, @20];
            polyline.spans = GMSStyleSpans(polyline.path, styles, lengths, kGMSLengthRhumb);
            polyline.map = self.mapView;
            
        } else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            NSMutableArray *pathArray = [step objectForKey:@"path"];
            NSEnumerator *enmueratorpathArray = [pathArray objectEnumerator];
            NSMutableDictionary *onepath;
            
            GMSMutablePath *path = [GMSMutablePath path];
            while (onepath = [enmueratorpathArray nextObject]) {
                [path addCoordinate:CLLocationCoordinate2DMake([[onepath objectForKey:@"lat"] doubleValue], [[onepath objectForKey:@"lng"] doubleValue])];
            }
            //            NSLog(@"TEST::: STEP::: %@", step);
//            NSArray *pathArray = [CommonAPI polylineWithEncodedString: [[step objectForKey:@"polyline"] objectForKey:@"points"]];
//            NSEnumerator *enmueratorpathArray = [pathArray objectEnumerator];
//            CLLocation *oneLocation;
//            
//            GMSMutablePath *path = [GMSMutablePath path];
//            while (oneLocation = [enmueratorpathArray nextObject]) {
//                [path addCoordinate:[oneLocation coordinate]];
//                //                    [path addCoordinate:CLLocationCoordinate2DMake([[[onepath allValues] objectAtIndex:0] doubleValue], [[[onepath allValues] objectAtIndex:1] doubleValue])];
//            }
            
            GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
            
            //            if (i==self.selected_route_number) {
            //            NSLog(@"appDelegate.selectedRouteNumber:%d,%ld", colorIndex, (long)appDelegate.selectedRouteNumber);
            if (colorIndex== appDelegate.selectedRouteNumber) {
                selectedRouteDic = step;
                

            }
            
            polyline.strokeColor = [colorArray objectAtIndex:(colorIndex++)%[colorArray count]];
            polyline.strokeWidth = 6.f;
            polyline.geodesic = YES;
            
            NSMutableDictionary *departure_stop = [[step objectForKey:@"transit"] objectForKey:@"departure_stop"];
            NSMutableDictionary *arrival_stop = [[step objectForKey:@"transit"] objectForKey:@"arrival_stop"];
            
            GMSMarker *departure_stop_marker = [[GMSMarker alloc] init];
            departure_stop_marker.title = [departure_stop objectForKey:@"name"];
            departure_stop_marker.icon = [UIImage imageNamed:@"yellowmarker_small@2x.png"];
            departure_stop_marker.position = ((CLLocation *)[CommonAPI polylineWithEncodedString:[[step objectForKey:@"polyline"] objectForKey:@"points"]].firstObject).coordinate;
            departure_stop_marker.map = self.mapView;
            
            GMSMarker *arrival_stop_marker = [[GMSMarker alloc] init];
            arrival_stop_marker.title = [arrival_stop objectForKey:@"name"];
            arrival_stop_marker.icon = [UIImage imageNamed:@"yellowmarker_small@2x.png"];
            arrival_stop_marker.position = ((CLLocation *)[CommonAPI polylineWithEncodedString:[[step objectForKey:@"polyline"] objectForKey:@"points"]].lastObject).coordinate;
            arrival_stop_marker.map = self.mapView;
            
            //            } else {
            //                polyline.strokeColor = [UIColor colorWithRed:147/255.0 green:147/255.0 blue:147/255.0 alpha:1];
            //                polyline.strokeWidth = 4.f;
            //                polyline.geodesic = YES;
            //            }
            polyline.map = self.mapView;
            
        }
    }

}

- (void)startAnimationToFadeEverything {
    self.CSAnimationView_Top.alpha=0;
    
    self.CSAnimationView_Map.alpha=0;
    self.cSAV_loadEarlierCheckpoint.alpha = 0;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
//    NSLog(@"Did update to location");
    
//    NSLog(@"LAST-latitude:::%f, %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    if ([goTimer isValid]) {
        if (myLastLocation.latitude<0.0001 && myLastLocation.longitude<0.0001) {
            myLastLocation.latitude = newLocation.coordinate.latitude;
            myLastLocation.longitude = newLocation.coordinate.longitude;
        }
        CLLocation *location1 = [[CLLocation alloc] initWithLatitude:myLastLocation.latitude longitude:myLastLocation.longitude];
        CLLocation *location2 = [[CLLocation alloc] initWithLatitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
        float one_distance = [location1 distanceFromLocation:location2];
//        NSLog(@"ONE-DISTANCE:::%f", one_distance);
        if (one_distance>500)
            return;
        else if (one_distance<2)
            return;
        
        GMSMutablePath *path = [GMSMutablePath path];
        [path addCoordinate:myLastLocation];
        //    [path addCoordinate:CLLocationCoordinate2DMake(36.197724, -86.711088)];
        [path addCoordinate: newLocation.coordinate];
        GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
        polyline.strokeColor = [UIColor redColor];
        polyline.strokeWidth = 4.5f;
        polyline.geodesic = YES;
        
        polyline.map = self.mapView;
        
        actualDistance_every5seconds += one_distance;
        actualDistance += one_distance;
        
        myLastLocation.latitude = newLocation.coordinate.latitude;
        myLastLocation.longitude = newLocation.coordinate.longitude;
    }
}
/*
-(void)getUpdatedLocationAndDrawRouteOnMap {
    
    if ([goTimer isValid]) {
        if (myLastLocation.latitude<0.0001 && myLastLocation.longitude<0.0001) {
            myLastLocation.latitude = self.locationManager.location.coordinate.latitude;
            myLastLocation.longitude = self.locationManager.location.coordinate.longitude;
        }
        CLLocation *location1 = [[CLLocation alloc] initWithLatitude:myLastLocation.latitude longitude:myLastLocation.longitude];
        CLLocation *location2 = [[CLLocation alloc] initWithLatitude:self.locationManager.location.coordinate.latitude longitude:self.locationManager.location.coordinate.longitude];
        float one_distance = [location1 distanceFromLocation:location2];
        NSLog(@"ONE-DISTANCE:::%f", one_distance);
        if (one_distance>500)
            return;
        else if (one_distance<2)
            return;
        
        GMSMutablePath *path = [GMSMutablePath path];
        [path addCoordinate:myLastLocation];
        //    [path addCoordinate:CLLocationCoordinate2DMake(36.197724, -86.711088)];
        [path addCoordinate: self.locationManager.location.coordinate];
        GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
        polyline.strokeColor = [UIColor redColor];
        polyline.strokeWidth = 4.5f;
        polyline.geodesic = YES;
        
        polyline.map = self.mapView;
        
        actualDistance_every5seconds += one_distance;
        actualDistance += one_distance;
        
        myLastLocation.latitude = self.locationManager.location.coordinate.latitude;
        myLastLocation.longitude = self.locationManager.location.coordinate.longitude;
    }
    
}
 */

//- (void)calculateDistance_every5seconds {
//    CLLocation *location1 = [[CLLocation alloc] initWithLatitude:appDelegate.locationTracker.myLastLocation.latitude longitude:appDelegate.locationTracker.myLastLocation.longitude];
//    CLLocation *location2 = [[CLLocation alloc] initWithLatitude:self.locationManager.location.coordinate.latitude longitude:self.locationManager.location.coordinate.longitude];
//    float one_distance = [location1 distanceFromLocation:location2];
//    if (one_distance<1000) {
//        actualDistance_every5seconds += [location1 distanceFromLocation:location2];
//        actualDistance += [location1 distanceFromLocation:location2];
//    }
//}

-(void)moveCameraToCurrentLocation {
    if (fakeLocationFlag) {
        CLLocationCoordinate2D center;
        center.latitude = fakeLat;
        center.longitude = fakeLon;
        
        [self.mapView animateToLocation:center];
    } else {
//        [self.mapView animateToLocation:appDelegate.locationTracker.myLocation];
        [self.mapView animateToLocation:self.locationManager.location.coordinate];
    }
}

-(void)updateTimeLabel {
    
    NSTimeInterval goTimer_end = [[NSDate date] timeIntervalSince1970];
    
    // If idle for more than 5 seconds then move camera to the user's current location
    //    if (((int)goTimer_end-(int)lastTimeSinceMapIdleAtCameraPosition)>5)
    //        [self moveCameraToCurrentLocation];
    if (self.cSAnimationView_wantToTrackLocation.isHidden)
        [self moveCameraToCurrentLocation];
    
    
    if ((int)goTimer_end%10==0) {
//        [self calculateDistance_every5seconds];
        [self savePreviousTripSection_every5seconds];
    }
    
    if ((int)goTimer_end%5==0) {
        [self getVehiclePositionsUpdate];
        [self getTripUpdate];
    }
    
    if (stepInfoToDisplay_dic) {
        
        int step_index = [[stepInfoToDisplay_dic objectForKey:@"step_index"] intValue];
        if (step_index==trip_status_index) {
            self.uILabel_realtimeLabel2.text = [NSString stringWithFormat:@"Get off the current route %@", [stepInfoToDisplay_dic objectForKey:@"route_id"]];
            self.uILabel_realtimeLabel2_1.text = [NSString stringWithFormat:@"At stop: %@", [stepInfoToDisplay_dic objectForKey:@"end_stop_name"]];
            
            int d1;
            if ([[stepInfoToDisplay_dic objectForKey:@"end_stop_timestamp_realtime"] intValue]==0) {
                d1 = [[stepInfoToDisplay_dic objectForKey:@"end_stop_timestamp"] intValue] - goTimer_end;
                [self.uIButton_realtime_or_schedule setBackgroundColor:[UIColor darkGrayColor]];
                [self.uIButton_realtime_or_schedule setTitle:@"schedule" forState:UIControlStateNormal];
                
                self.uILabel_realtimeLabel2_2.text = @"";
            } else {
                d1 = [[stepInfoToDisplay_dic objectForKey:@"end_stop_timestamp_realtime"] intValue] - goTimer_end;
                [self.uIButton_realtime_or_schedule setBackgroundColor:DefaultGreen];
                [self.uIButton_realtime_or_schedule setTitle:@"realtime" forState:UIControlStateNormal];
                
        
            }
            
            if (d1>=0) {
                self.uILabel_realtimeLabel2_2.text = [@"Time left: " stringByAppendingString:[NSString stringWithFormat:@"%02.0f:%02.0f", (double)(d1/3600), (double)((d1%3600)/60)]];
                self.uILabel_realtimeLabel2_2.textColor = DefaultDarkerGreen;
            } else {
                self.uILabel_realtimeLabel2_2.text = @"Oops! You probably missed the bus stop.";
                self.uILabel_realtimeLabel2_2.textColor = DefaultDarkerGreen;
                
                // Replan alert if missed
                if ([self.ifMissedThenPopResetFlag isEqualToString:@"YES"]) {
                    self.ifMissedThenPopResetFlag = @"NO";
                    UIAlertController * alert=   [UIAlertController
                                                  alertControllerWithTitle:@""
                                                  message:@"Oops! You probably missed the bus stop. Do you want to replan the route to your destination for now?"
                                                  preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* yesButton = [UIAlertAction
                                                actionWithTitle:@"Yes, please"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action)
                                                {
                                                    //Handel your yes please button action here
                                                    [alert dismissViewControllerAnimated:YES completion:nil];
                                                    NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"uuid==%@", self.calendar_ScheduledTrip_uuid ] inManagedObjectContext:objectContext];
                                                    if ([items count]>0) {
                                                        ScheduledTrip *scheduledTrip = items.lastObject;
                                                        appDelegate.reschedule_route_dictionary = [[NSMutableDictionary alloc] init];
                                                        [appDelegate.reschedule_route_dictionary setObject: [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.latitude] forKey:@"departureLat"];
                                                        [appDelegate.reschedule_route_dictionary setObject: [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.longitude] forKey:@"departureLng"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.arrivalLat forKey:@"arrivalLat"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.arrivalLng forKey:@"arrivalLng"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.departureTime forKey:@"departureTime"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.arrivalTime forKey:@"arrivalTime"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.fromAddress forKey:@"fromAddress"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.toAddress forKey:@"toAddress"];
                                                        [objectContext deleteObject:scheduledTrip];
                                                        [CoreDataHelper saveManagedObjectContext:objectContext];
                                                    }
                                                    
                                                    self.tabBarController.selectedIndex=0;
                                                    
                                                }];
                    UIAlertAction* noButton = [UIAlertAction
                                                actionWithTitle:@"No"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action)
                                                {
                                                    
                                                    [alert dismissViewControllerAnimated:YES completion:nil];
                                                    
                                                }];
                    
                    [alert addAction:yesButton];
                    [alert addAction:noButton];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }
            if (d1%2==0)
                self.uILabel_realtimeLabel2_2.alpha = 0.7;
            else
                self.uILabel_realtimeLabel2_2.alpha = 1;
        } else {
            self.uILabel_realtimeLabel2.text = [NSString stringWithFormat:@"Get on route %@", [stepInfoToDisplay_dic objectForKey:@"route_id"]];
            self.uILabel_realtimeLabel2_1.text = [NSString stringWithFormat:@"At Stop: %@", [stepInfoToDisplay_dic objectForKey:@"start_stop_name"]];
            
            int d1;
            if ([[stepInfoToDisplay_dic objectForKey:@"start_stop_timestamp_realtime"] intValue]==0) {
                
                d1 = [[stepInfoToDisplay_dic objectForKey:@"start_stop_timestamp"] intValue] - goTimer_end;
                [self.uIButton_realtime_or_schedule setBackgroundColor:[UIColor darkGrayColor]];
                [self.uIButton_realtime_or_schedule setTitle:@"schedule" forState:UIControlStateNormal];
                
                self.uILabel_realtimeLabel2_2.text = @"";
            } else {
                d1 = [[stepInfoToDisplay_dic objectForKey:@"start_stop_timestamp_realtime"] intValue] - goTimer_end;
                [self.uIButton_realtime_or_schedule setBackgroundColor:DefaultGreen];
                [self.uIButton_realtime_or_schedule setTitle:@"realtime" forState:UIControlStateNormal];

            }
            if (d1>=0) {
                self.uILabel_realtimeLabel2_2.text =  [@"Time left: " stringByAppendingString:[NSString stringWithFormat:@"%02.0f:%02.0f", (double)(d1/3600), (double)((d1%3600)/60)]];
                self.uILabel_realtimeLabel2_2.textColor = DefaultDarkerGreen;
            } else {
                self.uILabel_realtimeLabel2_2.text = @"Oops! You probably missed the bus...";
                self.uILabel_realtimeLabel2_2.textColor = DefaultDarkerGreen;
                
                // Replan alert if missed
                if ([self.ifMissedThenPopResetFlag isEqualToString:@"YES"]) {
                    self.ifMissedThenPopResetFlag = @"NO";
                    UIAlertController * alert=   [UIAlertController
                                                  alertControllerWithTitle:@""
                                                  message:@"Oops! You probably missed the bus. The app is showing the next available bus on the route. Do you want to replan the route to your destination? "
                                                  preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* yesButton = [UIAlertAction
                                                actionWithTitle:@"Yes, please"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action)
                                                {
                                                    //Handel your yes please button action here
                                                    [alert dismissViewControllerAnimated:YES completion:nil];
                                                    NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"uuid==%@", self.calendar_ScheduledTrip_uuid ] inManagedObjectContext:objectContext];
                                                    if ([items count]>0) {
                                                        ScheduledTrip *scheduledTrip = items.lastObject;
                                                        appDelegate.reschedule_route_dictionary = [[NSMutableDictionary alloc] init];
                                                        [appDelegate.reschedule_route_dictionary setObject: [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.latitude] forKey:@"departureLat"];
                                                        [appDelegate.reschedule_route_dictionary setObject: [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.longitude] forKey:@"departureLng"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.arrivalLat forKey:@"arrivalLat"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.arrivalLng forKey:@"arrivalLng"];
                                                        [appDelegate.reschedule_route_dictionary setObject: [NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]] forKey:@"departureTime"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.arrivalTime forKey:@"arrivalTime"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.fromAddress forKey:@"fromAddress"];
                                                        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.toAddress forKey:@"toAddress"];
                                                        [objectContext deleteObject:scheduledTrip];
                                                        [CoreDataHelper saveManagedObjectContext:objectContext];
                                                    }
                                                    
                                                    UITabBarController *presentingViewController = (UITabBarController *)self.presentingViewController;
                                                    presentingViewController.selectedIndex=0;
                                                    [self dismissViewControllerAnimated:YES completion:nil];
                                                    
                                                }];
                    UIAlertAction* noButton = [UIAlertAction
                                               actionWithTitle:@"No"
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action)
                                               {
                                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                                   
                                               }];
                    
                    [alert addAction:yesButton];
                    [alert addAction:noButton];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }
            if (d1%2==0)
                self.uILabel_realtimeLabel2_2.alpha = 0.7;
            else
                self.uILabel_realtimeLabel2_2.alpha = 1;
        }
        //
        //        [self.uIButton_realtime_or_schedule setBackgroundColor:DefaultGreen];
        //        [self.uIButton_realtime_or_schedule setTitle:@"realtime" forState:UIControlStateNormal];
    }
    
    int d = goTimer_end-goTimer_start;
    
    self.uILabel_goTimer.text = [NSString stringWithFormat:@"%02.0f:%02.0f:%02.0f", (goTimer_end-goTimer_start)/3600, (double)((d%3600)/60), (double)(d%60)];
    
    //    [self queryDataFrom:[NSDate dateWithTimeIntervalSince1970:goTimer_start] toDate:[NSDate dateWithTimeIntervalSince1970:goTimer_end]];
}

-(void)initDic_ActualTrip {
    //    dic_actualTrip = [[NSMutableDictionary alloc] initWithCapacity:5];
    //    [dic_actualTrip setValue:@"" forKey:@"searchID"];
    
    array_actualTrip = [[NSMutableArray alloc] initWithCapacity:3];
    startTime_eachSection = [[NSDate date] timeIntervalSince1970];
    actualDistance=0;
}

-(void)initDic_ActualTrip_every5seconds {
    startTime_eachSection_every5seconds = [[NSDate date] timeIntervalSince1970];
    actualDistance_every5seconds=0;
}

-(void)dataCollection_actualTrip {
    NSMutableDictionary *dic_actualTrip = [[NSMutableDictionary alloc] initWithCapacity:3];
    [dic_actualTrip setValue:array_actualTrip forKey:@"tripMarkers"];
    if (!searchID)
        searchID = @"[searchID]";
    [dic_actualTrip setValue:searchID forKey:@"searchID"];
    
    NSString *submitURL = [@"https://c3stem.isis.vanderbilt.edu" stringByAppendingString:@"/saveActualTrip"];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:submitURL]];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    //    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"thub_demo" forHTTPHeaderField:@"Authorization"];
    [manager.requestSerializer setValue: @"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"application/json" , nil];
    
    NSLog(@"dataCollection_actualTrip: %@",dic_actualTrip);
    
    [manager POST:submitURL parameters:dic_actualTrip success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"dataCollection: %@",responseObject);
        
        NSMutableDictionary *responseJSON = [[NSMutableDictionary alloc] initWithDictionary:(NSMutableDictionary *)responseObject];
        
        NSLog(@"dataCollectionYES: %@",[responseJSON objectForKey:@"response"]);
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"dataCollection - failure: %@",error);
    }];
}

-(void)addToSummary:(float) amount forName:(NSString *)name {
    // pointer to standart user defaults
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:name]) {
        float tmp = [[defaults objectForKey:name] floatValue];
        tmp += amount;
        [defaults setObject:[NSNumber numberWithFloat:tmp ] forKey:name];
    } else {
        [defaults setObject:[NSNumber numberWithFloat:amount ] forKey:name];
    }

    
    NSLog(@"[defaults objectForKey:%@]: %@", name, [defaults objectForKey:name]);
    [defaults synchronize];
}

-(void)savePreviousTripSection {
    NSTimeInterval endTime_eachSection = [[NSDate date] timeIntervalSince1970];
    
    NSMutableDictionary *dic_eachSection = [[NSMutableDictionary alloc] initWithCapacity:5];
    [dic_eachSection setValue:[NSString stringWithFormat:@"%.0f", endTime_eachSection] forKey:@"actual_arrival_time"];
    [dic_eachSection setValue:[NSString stringWithFormat:@"%.0f", startTime_eachSection] forKey:@"actual_departure_time"];
    int step_index = [[stepInfoToDisplay_dic objectForKey:@"step_index"] intValue];
    if (step_index==trip_status_index) {
        [dic_eachSection setValue:@"TRANSIT" forKey:@"travel_mode"];
//        [self addToSummary:(endTime_eachSection-startTime_eachSection) forName:@"transit_time"];
        
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        NSNumber *gasPrice = [defaults valueForKey:@"gasPrice"];
//        [self addToSummary:[gasPrice floatValue]/1609.3*actualDistance forName:@"gas_saving"];
//        [self addToSummary:actualDistance forName:@"transit_points"];
//        [self addToSummary:actualDistance forName:@"impact_points"];
    } else {
        [dic_eachSection setValue:@"WALKING" forKey:@"travel_mode"];
//        [self addToSummary:(endTime_eachSection-startTime_eachSection) forName:@"walking_time"];
//        [self addToSummary:0.057*actualDistance forName:@"calories_burned"];
    }
    
    [dic_eachSection setValue:[NSString stringWithFormat:@"%.0f", actualDistance] forKey:@"actualWalkDistance"];
    
    NSLog(@"dic_eachSection: %@", dic_eachSection);
    [array_actualTrip addObject:dic_eachSection];
    
    startTime_eachSection = endTime_eachSection;
    actualDistance=0;
}

-(void)savePreviousTripSection_every5seconds {
    NSTimeInterval endTime_eachSection_every5seconds = [[NSDate date] timeIntervalSince1970];
    
    int step_index = [[stepInfoToDisplay_dic objectForKey:@"step_index"] intValue];
    if (step_index==trip_status_index) {
        [self addToSummary:(endTime_eachSection_every5seconds-startTime_eachSection_every5seconds) forName:@"transit_time"];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *gasPrice = [defaults valueForKey:@"gasPrice"];
        [self addToSummary:[gasPrice floatValue]/1609.3*actualDistance_every5seconds forName:@"gas_saving"];
        [self addToSummary:actualDistance_every5seconds forName:@"transit_points"];
        [self addToSummary:actualDistance_every5seconds forName:@"impact_points"];
    } else {
        [self addToSummary:(endTime_eachSection_every5seconds-startTime_eachSection_every5seconds) forName:@"walking_time"];
        [self addToSummary:0.057*actualDistance_every5seconds forName:@"calories_burned"];
    }
    
    startTime_eachSection_every5seconds = endTime_eachSection_every5seconds;
    actualDistance_every5seconds=0;
}

- (IBAction)didTapGo:(id)sender {
    
    if (viewStatus==ViewStatus_mapview) {
        [self setTabBarEnabled:NO];
        
        [self updateCheckpoint:0];
        
        [self initDic_ActualTrip];
        [self initDic_ActualTrip_every5seconds];
        
        self.CSAnimationView_Top.backgroundColor = TopBarRealtimeGoColor;
        
        [self getVehiclePositionsUpdate];
        
        viewStatus=ViewStatus_mapview_tripStarted;
        [self.uIButton_Go setTitle:@"STOP" forState:UIControlStateNormal];
        [self.uIButton_Go setBackgroundColor:[UIColor lightGrayColor]];
        
        //
        self.cSAnimationView_tripInfo.hidden=YES;
        
        
        goTimer_start = [[NSDate date] timeIntervalSince1970];
        lastTimeSinceMapIdleAtCameraPosition = goTimer_start;
        
        if (stepInfoToDisplay_dic) {
            [stepInfoToDisplay_dic setValue: [NSNumber numberWithInt:0] forKey:@"start_stop_timestamp_realtime"];
            [stepInfoToDisplay_dic setValue: [NSNumber numberWithInt:0] forKey:@"end_stop_timestamp_realtime"];
        }
        [self updateTimeLabel];
        
        
        
        //        // Steps
        //        if ([CMPedometer isStepCountingAvailable]) {
        //
        //            self.pedometer = [[CMPedometer alloc] init];
        //        }
        //        else {
        //            self.uILabel_calories.text = @"Not available";
        //        }
        //        [self.pedometer startPedometerUpdatesFromDate:[NSDate date]
        //                                          withHandler:^(CMPedometerData *pedometerData, NSError *error) {
        //                                              dispatch_async(dispatch_get_main_queue(), ^{
        //
        //                                                  NSLog(@"data:%@, error:%@", pedometerData, error);
        //                                              });
        //                                          }];
        
        [goTimer invalidate];
        goTimer=nil;
        goTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimeLabel) userInfo:nil repeats:YES];
        
        [self updateMapCenterLocation];
        
    } else {
        [self setTabBarEnabled:YES];
        
        self.CSAnimationView_Top.backgroundColor = TopBarDefaultColor;
        
        viewStatus=ViewStatus_mapview;
        [self.uIButton_Go setTitle:@"GO" forState:UIControlStateNormal];
        [self.uIButton_Go setBackgroundColor: DefaultLighterGreen];
        self.cSAnimationView_wantToTrackLocation.hidden = YES;
        
        //
        self.cSAnimationView_tripInfo.hidden=NO;
        [self showcSAnimationView_tripInfo];
        
        [goTimer invalidate];
        goTimer=nil;
        
        NSEnumerator *enmueratorMarker = [busMarkers objectEnumerator];
        GMSMarker *oneMarker;
        while (oneMarker = [enmueratorMarker nextObject]) {
            oneMarker.map = nil;
        }
        
        //        [self.mapView clear ];
        
        [self showRoute];
        
    }
    [self UpdateViewByViewStatus];
}

- (IBAction)didTagNextSegment:(id)sender {
    [self.cSAnimationView_wantToTrackLocation setHidden:YES];
    
    [self savePreviousTripSection];
    
    trip_status_index = trip_status_index+1;
    
    if (trip_status_index>=[[[[route_dic_from_database objectForKey:@"legs"] objectAtIndex:0] objectForKey:@"steps"] count]) {
        [self didTapGo:nil];
        
        [self dataCollection_actualTrip];
        [self updateCheckpoint:-1];
    } else {
        [self updateCheckpoint:trip_status_index];
    }
    self.cSAnimationView_RealtimeLabel2.hidden = YES;
    self.uILabel_realtimeLabel2.text = @"";
    self.uILabel_realtimeLabel2_1.text=@"";
    self.uILabel_realtimeLabel2_2.text=@"";
    stepInfoToDisplay_dic=nil;
    [self UpdateViewByViewStatus];
    
    [self updateMapCenterLocation];
}

-(void)updateMapCenterLocation {
    //
    BOOL flag = false;
    if(route_dic_from_database)
        if ([route_dic_from_database isKindOfClass:[NSMutableDictionary class]] || [route_dic_from_database isKindOfClass:[NSDictionary class]])
            if ([route_dic_from_database objectForKey:@"legs"])
                flag=true;
    if (!flag)
        return;
    
    if (viewStatus==ViewStatus_mapview) {
        [self showRoute];
        return;
    }
    
    NSMutableDictionary *leg_array = [[route_dic_from_database objectForKey:@"legs"] objectAtIndex:0];
    NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
    if ([steps_array objectAtIndex:trip_status_index]) {
        NSMutableDictionary *step = [steps_array objectAtIndex:trip_status_index];
        //        double lat=[[[[step objectForKey:@"start_point"] allValues] objectAtIndex:0] doubleValue];
        //        double lon=[[[[step objectForKey:@"start_point"] allValues] objectAtIndex:1] doubleValue];
        //        if (lat<lon) {
        //            double t = lat;
        //            lat=lon;
        //            lon=t;
        //        }
        NSString *one_polyline = [[step objectForKey:@"polyline"] objectForKey:@"points"];
        NSArray *coordArray = [CommonAPI polylineWithEncodedString:one_polyline];
        CLLocationCoordinate2D coordinateSouthWest = ((CLLocation *)coordArray.firstObject).coordinate;
        
        //        lat=[[[[step objectForKey:@"end_point"] allValues] objectAtIndex:0] doubleValue];
        //        lon=[[[[step objectForKey:@"end_point"] allValues] objectAtIndex:1] doubleValue];
        //        if (lat<lon) {
        //            double t = lat;
        //            lat=lon;
        //            lon=t;
        //        }
        
        CLLocationCoordinate2D coordinateNorthEast = ((CLLocation *)coordArray.lastObject).coordinate;
        
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:coordinateSouthWest coordinate:coordinateNorthEast];
        
        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds]];
        
        GMSCameraPosition *camera = [self.mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(55+55+35, 35, 45+15, 35)];
        [self.mapView animateToCameraPosition:camera];
    }
    
}

- (void)setTabBarEnabled:(BOOL) trueOrFalse {
    [[[[self.tabBarController tabBar] items] objectAtIndex:0] setEnabled:trueOrFalse];
    [[[[self.tabBarController tabBar] items] objectAtIndex:1] setEnabled:trueOrFalse];
    [[[[self.tabBarController tabBar] items] objectAtIndex:2] setEnabled:trueOrFalse];
    [[[[self.tabBarController tabBar] items] objectAtIndex:3] setEnabled:trueOrFalse];
    [[[[self.tabBarController tabBar] items] objectAtIndex:4] setEnabled:trueOrFalse];
}

- (IBAction)didTapBrowse:(id)sender {
    if (self.cSAnimationView_browse.hidden) {
        self.cSAnimationView_browse.hidden = false;
        [self.cSAnimationView_browse startCanvasAnimation];
    } else {
        self.cSAnimationView_browse.hidden = true;
        //        [self getNearbyBusesAndShowOnMap];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"browseView_embedded"]) {
        embeddedBrowseTableViewController = (EmbeddedBrowseTableViewController *) [segue destinationViewController];
    }
}
- (IBAction)didTapTrackRealtimeLocation:(id)sender {
    [self.cSAnimationView_wantToTrackLocation setHidden:YES];
    [self moveCameraToCurrentLocation];
}

- (IBAction)didTapRoutes:(id)sender {
    self.cSAnimationView_browse.hidden = YES;
    QueryViewController * queryViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"QueryViewController"];
    [self presentViewController:queryViewController animated:YES completion:nil];
}
- (IBAction)didTapBrowseOK:(id)sender {
    [self didTapBrowse:nil];
}
- (IBAction)didTapDismissViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (array_actualTrip)
        if ([array_actualTrip count]>0) {
            [self dataCollection_actualTrip];
        }
}
- (void)updateCheckpoint:(int)checkpoint  {
    NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"uuid==%@", self.calendar_ScheduledTrip_uuid ] inManagedObjectContext:objectContext];
    if ([items count]>0) {
        ScheduledTrip *old_scheduledTrip = items.lastObject;
        ScheduledTrip *scheduledTrip = [CoreDataHelper insertManagedObjectOfClass:[ScheduledTrip class] inManagedObjectContext:objectContext ];
        scheduledTrip.arrivalLat = old_scheduledTrip.arrivalLat;
        scheduledTrip.arrivalLng = old_scheduledTrip.arrivalLng;
        scheduledTrip.arrivalText = old_scheduledTrip.arrivalText;
        scheduledTrip.arrivalTime = old_scheduledTrip.arrivalTime;
        scheduledTrip.departureLat = old_scheduledTrip.departureLat;
        scheduledTrip.departureLng = old_scheduledTrip.departureLng;
        scheduledTrip.departureText = old_scheduledTrip.departureText;
        scheduledTrip.departureTime = old_scheduledTrip.departureTime;
        scheduledTrip.fromAddress = old_scheduledTrip.fromAddress;
        scheduledTrip.toAddress = old_scheduledTrip.toAddress;
        scheduledTrip.googleTripDic = old_scheduledTrip.googleTripDic;
        scheduledTrip.isRecurring = old_scheduledTrip.isRecurring;
        scheduledTrip.searchID = old_scheduledTrip.searchID;
        scheduledTrip.checkpoint = [NSNumber numberWithInt:checkpoint];
        scheduledTrip.uuid = old_scheduledTrip.uuid;
        
        for (ScheduledTrip *old_scheduledTrip in items) {
            [objectContext deleteObject:old_scheduledTrip];
        }
        
        [CoreDataHelper saveManagedObjectContext:objectContext];
    }
}
- (IBAction)didTap_loadEarlierCheckpoint_resume:(id)sender {
    self.uIButton_Go.enabled = YES;
    self.cSAV_loadEarlierCheckpoint.hidden = YES;
    
    NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"uuid==%@", self.calendar_ScheduledTrip_uuid ] inManagedObjectContext:objectContext];
    if ([items count]>0) {
        ScheduledTrip *scheduledTrip = items.lastObject;
        if ([scheduledTrip.checkpoint intValue]>0) {
            trip_status_index = [scheduledTrip.checkpoint intValue]-1;
            [self didTapGo:nil];
            [self didTagNextSegment:nil];
        } else if ([scheduledTrip.checkpoint intValue]==0) {
            trip_status_index = [scheduledTrip.checkpoint intValue];
            [self didTapGo:nil];
        }
    }
    
    
}

- (IBAction)didTap_loadEarlierCheckpoint_reset:(id)sender {
    self.uIButton_Go.enabled = YES;
    self.cSAV_loadEarlierCheckpoint.hidden = YES;
    [self updateCheckpoint:-1];
}
@end
