//
//  RouteQueryViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 12/2/15.
//  Copyright © 2015 Fangzhou Sun. All rights reserved.
//

#import "RouteQueryViewController.h"
#import "AppDelegate.h"
#import "ColorConstants.h"
#import "AKPickerView.h"
#import "AFNetworking.h"
#import <ProtocolBuffers/ProtocolBuffers.h>
#import "GtfsRealtime.pb.h"
//#import "RealtimeTripUpdates.h"

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]

@interface RouteQueryViewController () <AKPickerViewDataSource, AKPickerViewDelegate> {
    AKPickerView *pickerView;
    AppDelegate *appDelegate;
    
    
    NSArray *tripArrayForSelectedHeadsign;
    int moveCameraToBound_int;
    //    NSMutableDictionary *tripID_tripHeadsign_dic;
    NSMutableDictionary *map_coorForStopId;
    NSMutableDictionary *map_tripID_pathCoordinates;
    //    NSMutableDictionary *map_tripID_busesArray;
    
    /////
    NSString *selectedRoute;
    NSString *selectedTrip;
    NSMutableArray *allRouteId_sorted;
    NSMutableArray *allTripId_sorted;
    NSMutableArray *array_busStopMarkers;
    NSMutableArray *array_busMarkers;
    NSDictionary *map_selectedStop;
    
    NSMutableDictionary *nSMDictionary_tripID_stops;
    NSMutableDictionary *nSMDictionary_routeID_tripID;
    NSMutableDictionary *nSMDictionary_tripID_busLocation;
    NSMutableDictionary *nSMDictionary_tripID_headsign;
    NSMutableDictionary *nSMDictionary_routeID_route_long_name;
    NSMutableDictionary *nSMDictionary_tripID_departureArrivalTime;
    NSMutableDictionary *nSMDictionary_tripID_staticStops;
    NSTimer *nSTimer_realtimeFeedUpdate;
    NSTimer *nSTimer_updateViewsByFeedUpdate;
    NSTimer *nSTimer_flicker_buses;
    NSInteger nSInteger_nSTimer_flicker_buses_counter;
    //    NSTimer *nSTimer_flicker_stops;
    
    NSArray *nSArray_tripIDsForRouteIDAndHeadSign;
    
    BOOL flag_busNameShown;
    
    NSMutableDictionary *nSMDictionary_tripID_numStops;
    NSMutableDictionary *nSMDictionary_tripIDStopID_staticDic;
}
@property (nonatomic, strong) NSMutableArray *titles;
@property (strong, nonatomic) GMSMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation RouteQueryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self hideEverything];
    flag_busNameShown = NO;
    // Do any additional setup after loading the view.
    nSMDictionary_tripID_stops = [[NSMutableDictionary alloc] initWithCapacity:5];
    nSMDictionary_tripID_headsign = [[NSMutableDictionary alloc] initWithCapacity:5];
    nSMDictionary_routeID_route_long_name = [[NSMutableDictionary alloc] initWithCapacity:5];
    nSMDictionary_tripID_departureArrivalTime = [[NSMutableDictionary alloc] initWithCapacity:5];
    nSMDictionary_tripID_busLocation = [[NSMutableDictionary alloc] init];
    nSMDictionary_tripID_numStops = [[NSMutableDictionary alloc] init];
    nSMDictionary_tripIDStopID_staticDic = [[NSMutableDictionary alloc] init];
    selectedTrip = @"";
    allTripId_sorted = [[NSMutableArray alloc] init];
    
    // AppDelegate
    appDelegate = ((AppDelegate*)[[UIApplication sharedApplication]delegate]);
    allRouteId_sorted = [[NSMutableArray alloc] initWithCapacity:50];
    
    moveCameraToBound_int = 0;
    
    //    [self showBusesForRoute];
    //    map_tripID_stopsArray = [[NSMutableDictionary alloc] initWithCapacity:5];
    //    map_tripID_busesArray = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    ///////////
    [self getCurrentLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:(BOOL)animated];
    NSLog(@"viewDidDisappear");
    [self hideEverything];
    [nSTimer_realtimeFeedUpdate invalidate];
    nSTimer_realtimeFeedUpdate=nil;
    [nSTimer_updateViewsByFeedUpdate invalidate];
    nSTimer_updateViewsByFeedUpdate=nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    nSTimer_realtimeFeedUpdate = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(realtimeFeedUpdate) userInfo:nil repeats:YES];
    [nSTimer_realtimeFeedUpdate fire];
    
    if (!pickerView) {
        pickerView = [[AKPickerView alloc] initWithFrame:self.uIView_aKPicker.bounds];
        pickerView.delegate = self;
        pickerView.dataSource = self;
        pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.uIView_aKPicker addSubview:pickerView];
        
        pickerView.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15];
        pickerView.textColor = [UIColor whiteColor];
        pickerView.highlightedTextColor = [UIColor whiteColor];
        pickerView.highlightedFont = [UIFont fontWithName:@"AvenirNext-Regular" size:15];
        pickerView.interitemSpacing = 20.0;
        pickerView.fisheyeFactor = 0.001;
        pickerView.pickerViewStyle = AKPickerViewStyle3D;
        pickerView.maskDisabled = false;
        pickerView.backgroundColor = [UIColor clearColor];
        
        self.uILabel_topInfo.text = [NSString stringWithFormat:@"REAL-TIME"];
        [self initMap];
        [self cSAnimationView_routePickerSetHidden:NO];
    } else {
        nSTimer_updateViewsByFeedUpdate = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(updateViewsByFeedUpdate) userInfo:nil repeats:YES];
        [nSTimer_updateViewsByFeedUpdate fire];
    }
    
    [self startAnimation];
    
    nSTimer_flicker_buses = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(flickerBus) userInfo:nil repeats:YES];
    [nSTimer_flicker_buses fire];
}

- (void)flickerBus {
    nSInteger_nSTimer_flicker_buses_counter++;
    if (nSInteger_nSTimer_flicker_buses_counter%4==0) {
        for (GMSMarker *bus_marker in array_busMarkers) {
            bus_marker.map = nil;
        }
    } else if (nSInteger_nSTimer_flicker_buses_counter%4==1) {
        for (GMSMarker *bus_marker in array_busMarkers) {
            bus_marker.map = self.mapView;
        }
    }
}

- (void)startAnimation {
    self.cSAV_topView.hidden=NO;
    self.cSAV_directionPickerView.hidden=NO;
    self.cSAV_mapView.hidden=NO;
    
    self.cSAV_directionPickerView.type = CSAnimationTypeFadeIn;
    self.cSAV_directionPickerView.duration = 0.3;
    self.cSAV_directionPickerView.delay = 0.0;
    [self.cSAV_directionPickerView startCanvasAnimation];
    
    self.cSAV_mapView.type = CSAnimationTypeFadeIn;
    self.cSAV_mapView.duration = 0.3;
    self.cSAV_mapView.delay = 0.0;
    [self.cSAV_mapView startCanvasAnimation];
    
    self.cSAV_topView.type = CSAnimationTypeSlideDown;
    self.cSAV_topView.duration = 0.3;
    self.cSAV_topView.delay = 0.0;
    [self.cSAV_topView startCanvasAnimation];
}

- (void)hideEverything {
    self.cSAV_topView.hidden=YES;
    self.cSAV_directionPickerView.hidden=YES;
    self.cSAV_mapView.hidden=YES;
}

-(BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    if (marker.userData) {
            map_selectedStop = marker.userData;
            [nSTimer_updateViewsByFeedUpdate fire];
            if ([map_selectedStop objectForKey:@"stop_sequence"] && [map_selectedStop objectForKey:@"stop_name"]) {
                self.uILabel_selectedStop_detail.text = [NSString stringWithFormat:@"%@. %@", [map_selectedStop objectForKey:@"stop_sequence"], [map_selectedStop objectForKey:@"stop_name"] ];
                [self.cSAV_mapView bringSubviewToFront: self.cSAV_selectedStopDetail];
                self.cSAV_selectedStopDetail.hidden = NO;
                self.cSAV_selectedStopDetail.type = CSAnimationTypeFadeIn;
                self.cSAV_selectedStopDetail.duration = 0.3;
                self.cSAV_selectedStopDetail.delay = 0.0;
                [self.cSAV_selectedStopDetail startCanvasAnimation];
                self.cSAV_selectedStopDetail.alpha = 0.85;
            }
    }
    return YES;
}

- (void) mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    self.cSAV_tripDetailsView.hidden = YES;
    self.cSAV_selectedStopDetail.hidden = YES;
    
    int zoom= mapView.camera.zoom;
    //    NSLog(@"TMP:::ZOOM:::%d", zoom);
    if (zoom>=16) {
        
        if (!flag_busNameShown) {
            //                        NSLog(@"TMP:::flag 1");
            flag_busNameShown = YES;
            [self showStopsForTripID: selectedTrip];
        }
    } else {
        if (flag_busNameShown) {
            //                        NSLog(@"TMP:::flag 2");
            flag_busNameShown = NO;
            [self showPathForTripID: selectedTrip];
            [self showStopsForTripID: selectedTrip];
        }
    }
}

- (void) mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    self.cSAV_tripDetailsView.hidden = NO;
    self.cSAV_tripDetailsView.type = CSAnimationTypeFadeIn;
    self.cSAV_tripDetailsView.duration = 0.3;
    self.cSAV_tripDetailsView.delay = 0.0;
    [self.cSAV_tripDetailsView startCanvasAnimation];
    self.cSAV_tripDetailsView.alpha = 0.85;
    
    if (map_selectedStop) {
        [self.cSAV_mapView bringSubviewToFront: self.cSAV_selectedStopDetail];
        self.cSAV_selectedStopDetail.hidden = NO;
        self.cSAV_selectedStopDetail.type = CSAnimationTypeFadeIn;
        self.cSAV_selectedStopDetail.duration = 0.3;
        self.cSAV_selectedStopDetail.delay = 0.0;
        [self.cSAV_selectedStopDetail startCanvasAnimation];
        self.cSAV_selectedStopDetail.alpha = 0.85;
    }
}

- (void)realtimeFeedUpdate {
    [self getTripUpdates];
    [self getBusLocationUpdates];
}

- (void)initialPickerView {
    if (pickerView)
    [pickerView removeFromSuperview];
    pickerView = [[AKPickerView alloc] initWithFrame:self.uIView_aKPicker.bounds];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.uIView_aKPicker addSubview:pickerView];
    
    pickerView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
    pickerView.textColor = [UIColor whiteColor];
    pickerView.highlightedTextColor = [UIColor whiteColor];
    pickerView.highlightedFont = [UIFont fontWithName:@"HelveticaNeue" size:15];
    pickerView.interitemSpacing = 20.0;
    pickerView.fisheyeFactor = 0.001;
    pickerView.pickerViewStyle = AKPickerViewStyle3D;
    pickerView.maskDisabled = false;
    pickerView.backgroundColor = [UIColor clearColor];
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

- (void)initMap {
    
    if(self.mapView) {
        [self.mapView clear];
        [self.mapView removeFromSuperview];
    }
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.locationManager.location.coordinate.latitude longitude:self.locationManager.location.coordinate.longitude zoom:12];
    if (self.locationManager.location.coordinate.latitude<100 || self.locationManager.location.coordinate.longitude<100)
        camera = [GMSCameraPosition cameraWithLatitude:36.159454 longitude:-86.782110 zoom:12];
    self.mapView = [GMSMapView mapWithFrame:self.cSAV_mapView.bounds camera:camera];
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    self.mapView.indoorEnabled = NO;
    [self.cSAV_mapView addSubview:self.mapView];
    [self.cSAV_mapView bringSubviewToFront:self.cSAV_routeSelectionView];
    [self.cSAV_mapView bringSubviewToFront:self.cSAV_tripDetailsView];
    self.uIView_busStopMarker.alpha=1;
}

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    if (component==0) {
        if (allRouteId_sorted)
        return [allRouteId_sorted count];
        else return 0;
    } else {
        if (allRouteId_sorted)
        return [allRouteId_sorted count];
        else return 0;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    if (component==0) {
        if ([allRouteId_sorted count]>row) {
            NSString *routeName = [nSMDictionary_routeID_route_long_name objectForKey:[[allRouteId_sorted objectAtIndex:row] stringValue]];
            if (!routeName || routeName.length<1) {
                routeName = [appDelegate.dbManager getRouteNameFromId:[[allRouteId_sorted objectAtIndex:row] stringValue]];
                if (routeName && routeName.length>0)
                [nSMDictionary_routeID_route_long_name setObject:routeName forKey:[[allRouteId_sorted objectAtIndex:row] stringValue]];
                else
                routeName = @"";
            }
            return [[[allRouteId_sorted objectAtIndex:row] stringValue] stringByAppendingString:[NSString stringWithFormat:@": %@", routeName]];
        } else {
            return @"";
        }
    } else {
        return @"";
    }
}

- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item {
    moveCameraToBound_int = 0;
    [nSTimer_updateViewsByFeedUpdate fire];
    map_selectedStop = nil;
    self.cSAV_selectedStopDetail.hidden = YES;
}

-(void)getTripUpdates {
    NSURL *URL=[NSURL URLWithString:@"http://transitdata.nashvillemta.org/TMGTFSRealTimeWebService/tripupdate/tripupdates.pb"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (!responseObject) return;
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
//        NSLog(@"-> getTripUpdates %@", feedMessage.entity);
        if ([feedMessage.entity count]==0)
            return;
        else {
            nSMDictionary_tripID_stops = [[NSMutableDictionary alloc] initWithCapacity:5];
            nSMDictionary_routeID_tripID = [[NSMutableDictionary alloc] initWithCapacity:5];
        }
        for (FeedEntity *feedEntity in feedMessage.entity) {
            if (feedEntity.tripUpdate.stopTimeUpdate && feedEntity.tripUpdate.trip.tripId && feedEntity.tripUpdate.trip.routeId) {
                
                //                TripUpdateStopTimeUpdate *tripUpdateStopTimeUpdate = [feedEntity.tripUpdate.stopTimeUpdate lastObject];
                
                NSMutableDictionary *nSMDictionary_trip = [[NSMutableDictionary alloc] initWithCapacity:5];
                NSString *tripId = feedEntity.tripUpdate.trip.tripId;
                NSString *routeId = feedEntity.tripUpdate.trip.routeId;
                
//                NSLog(@"-> feedEntity %@, %@", tripId, routeId);
//                NSLog(@"-> feedEntity, %@, %@", tripId, routeId);
                
                //                NSMutableArray *array_departureArrivalTime = [nSMDictionary_tripID_departureArrivalTime objectForKey:tripId];
                //                if (!array_departureArrivalTime) {
                //                    array_departureArrivalTime = [appDelegate.dbManager getDepartureAndArrivalTimeByTripID:tripId];
                //                    [nSMDictionary_tripID_departureArrivalTime setObject:array_departureArrivalTime forKey:tripId];
                //                }
                //                if ([array_departureArrivalTime objectAtIndex:1]<[[NSDate date] timeIntervalSince1970]) {
                //                    NSLog(@"TMP:::ENDED:::%ld, %f", [[array_departureArrivalTime objectAtIndex:2] longValue], [[NSDate date] timeIntervalSince1970]);
                //                    continue;
                //                }
                
                //                NSLog(@"TMP:::ENDED:::%ld, %f", [[array_departureArrivalTime objectAtIndex:2] longValue], [[NSDate date] timeIntervalSince1970]);
                [allRouteId_sorted addObject: [NSNumber numberWithInteger:[routeId integerValue]] ];
                
                NSMutableArray *tripArray = [nSMDictionary_routeID_tripID objectForKey:routeId];
                if (!tripArray) {
                    tripArray = [[NSMutableArray alloc] initWithCapacity:5];
                }
                [tripArray addObject:tripId];
                [nSMDictionary_routeID_tripID setObject:tripArray forKey:routeId];
                
                // Check if exist
//                NSLog(@"-> nSMDictionary_tripID_headsign %@", nSMDictionary_tripID_headsign);
                NSString *tripHeadsign = [nSMDictionary_tripID_headsign objectForKey:tripId];
                if (tripHeadsign) {
                } else {
                    tripHeadsign = [appDelegate.dbManager getTripHeadSignByTripID:tripId];
                    if (tripHeadsign)
                    [nSMDictionary_tripID_headsign setObject:tripHeadsign forKey:tripId];
                    else
                    continue;
                }
                NSMutableArray *nSMArray_stops = [[NSMutableArray alloc] initWithCapacity:10];
                for (TripUpdateStopTimeUpdate *tripUpdateStopTimeUpdate in feedEntity.tripUpdate.stopTimeUpdate) {
                    NSMutableDictionary *tripUpdateStopTimeUpdateDic = [[NSMutableDictionary alloc] initWithCapacity:4];
                    [tripUpdateStopTimeUpdateDic setObject:[NSNumber numberWithInt: tripUpdateStopTimeUpdate.stopSequence] forKey:@"stopSequence"];
                    [tripUpdateStopTimeUpdateDic setObject:[NSNumber numberWithLong: tripUpdateStopTimeUpdate.departure.time] forKey:@"time"];
                    [tripUpdateStopTimeUpdateDic setObject:[NSNumber numberWithInt: tripUpdateStopTimeUpdate.departure.delay] forKey:@"delay"];
                    [tripUpdateStopTimeUpdateDic setObject:tripUpdateStopTimeUpdate.stopId forKey:@"stopId"];
                    
                    [nSMArray_stops addObject:tripUpdateStopTimeUpdateDic];
                }
                [nSMDictionary_trip setObject:nSMArray_stops forKey:@"stops"];
                [nSMDictionary_trip setObject:tripHeadsign forKey:@"headsign"];
                
                NSLog(@"437:%@", nSMDictionary_trip);
                
                // Save to map
                [nSMDictionary_tripID_stops setObject:nSMDictionary_trip forKey:tripId];
            }
            NSLog(@"-> nSMDictionary_tripID_stops %@", nSMDictionary_tripID_stops);
        }
        allRouteId_sorted = [NSMutableArray arrayWithArray: [[[NSSet setWithArray:allRouteId_sorted] allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]] ];
        [self.uIPickerView_routes reloadAllComponents];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
}

- (void)getBusLocationUpdates{
    NSURL *URL = [NSURL URLWithString:@"http://transitdata.nashvillemta.org/TMGTFSRealTimeWebService/vehicle/vehiclepositions.pb"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // here we must create NSData object with received data...
//        NSLog(@"-> getBusLocationUpdates: response");
        if (!responseObject) return;
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
        for (FeedEntity *feedEntity in feedMessage.entity) {
            NSMutableDictionary *nSMDictionary_bus = [[NSMutableDictionary alloc] init];
            [nSMDictionary_bus setObject:[NSNumber numberWithFloat:feedEntity.vehicle.position.latitude] forKey:@"latitude"];
            [nSMDictionary_bus setObject:[NSNumber numberWithFloat:feedEntity.vehicle.position.longitude] forKey:@"longitude"];
            [nSMDictionary_tripID_busLocation setObject:nSMDictionary_bus forKey:feedEntity.vehicle.trip.tripId];
        }
        //        NSLog(@"TMP10:::%@",nSMDictionary_tripID_busLocation);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (!allTripId_sorted) return 0;
    if ([allTripId_sorted count]<4) {
        self.nSLayoutConstraint_cSAnimtionView_tripDetails_height.constant =[allTripId_sorted count]*52;
    } else {
        self.nSLayoutConstraint_cSAnimtionView_tripDetails_height.constant =3.4*52;
    }
    return [allTripId_sorted count];
    //    return 3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.uITableView_tripDetails deselectRowAtIndexPath:indexPath animated:YES];
    moveCameraToBound_int = 0;
    if (allTripId_sorted && [allTripId_sorted count]>indexPath.row)
    selectedTrip = [allTripId_sorted objectAtIndex:indexPath.row];
    [nSTimer_updateViewsByFeedUpdate fire];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TripCell" forIndexPath:indexPath];
    
    UIView *viewSelected = [(UILabel *)cell.contentView viewWithTag:-2];
    if (viewSelected) {
        [viewSelected removeFromSuperview];
    }
    UIView *viewSelected2 = [(UILabel *)cell.contentView viewWithTag:-3];
    if (viewSelected2) {
        [viewSelected2 removeFromSuperview];
    }
    
    if (!allTripId_sorted)
    return cell;
    if (indexPath.row!=[allTripId_sorted indexOfObject:selectedTrip]) {
        cell.backgroundColor = [UIColor whiteColor];
    } else {
        cell.backgroundColor = [UIColor whiteColor]; //UIColorFromRGB(0xd8c7fb); //Similar to TopBarRealtimeGoColor
        viewSelected = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, cell.contentView.frame.size.height)];
        viewSelected.tag = -2;
        viewSelected.backgroundColor = TopBarRealtimeGoColor;
        [cell.contentView addSubview:viewSelected];
        viewSelected2 = [[UIView alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width-8, 0, 8, cell.contentView.frame.size.height)];
        viewSelected2.tag = -3;
        viewSelected2.backgroundColor = TopBarRealtimeGoColor;
        [cell.contentView addSubview:viewSelected2];
    }
    
    //    NSString *tripID = [allTripId_sorted objectAtIndex:indexPath.row];
    //    NSString *str = [[nSMDictionary_tripID_stops objectForKey:[allTripId_sorted objectAtIndex:indexPath.row]]  objectForKey:@"maxInvalid"];
    //    if (!str || str.length==0)
    //        return cell;
    //    NSInteger maxInvalid = [str integerValue];
    //
    NSString *tripID = [allTripId_sorted objectAtIndex:indexPath.row];
    if (!tripID)
    tripID = @"";
    NSString *str_maxInvalid = @"";
    NSString *str_maxValid = @"";
    if ([nSMDictionary_tripID_stops objectForKey:tripID]) {
        str_maxInvalid = [[nSMDictionary_tripID_stops objectForKey:tripID] objectForKey:@"maxInvalid"];
        str_maxValid = [[nSMDictionary_tripID_stops objectForKey:tripID] objectForKey:@"maxValid"];
    }
    NSInteger maxInvalid = 0;
    NSInteger num_stops = 0;
    if (str_maxInvalid && str_maxValid) {
        maxInvalid = [[[nSMDictionary_tripID_stops objectForKey:[allTripId_sorted objectAtIndex:indexPath.row]] objectForKey:@"maxInvalid"] integerValue];
        num_stops = [[[nSMDictionary_tripID_stops objectForKey:[allTripId_sorted objectAtIndex:indexPath.row]] objectForKey:@"maxValid"] integerValue];
    }
    num_stops = [[nSMDictionary_tripID_numStops objectForKey:tripID] integerValue];
    
    float contentView_width = cell.contentView.frame.size.width;
    float label_height = 20;
    float label_width = 60;
    float padding_left = 73;
    float padding_right = 18;
    float length1 = (contentView_width-padding_left-padding_right)*maxInvalid/num_stops;
    float y1 = 21;
    float y2 = 29;
    float y3 = 3;
    
    
    NSLog(@"427: %@, %ld, %ld", tripID, (long)maxInvalid, (long)num_stops);
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    if ([map_selectedStop objectForKey:@"stop_sequence"])
        if (maxInvalid>[[map_selectedStop objectForKey:@"stop_sequence"] integerValue]) {
            cell.contentView.backgroundColor = UIColorFromRGB(0xdcdcdc);;

        }
    
    
    
    //
    NSMutableArray *array_departureArrivalTime = [nSMDictionary_tripID_departureArrivalTime objectForKey:tripID];
    
    UILabel *startTimeLabel = [(UILabel *)cell.contentView viewWithTag:1];
    if (!startTimeLabel) {
        startTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding_left, y2, label_width, label_height)];
        startTimeLabel.tag = 1;
        startTimeLabel.font = [UIFont systemFontOfSize:13.0];
        startTimeLabel.textColor = [UIColor darkGrayColor];
        startTimeLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:startTimeLabel];
    }
    if ([array_departureArrivalTime count]>0)
    startTimeLabel.text = [NSString stringWithFormat:@"\U0001F553%@", [array_departureArrivalTime objectAtIndex:0]];
    
    UILabel *endTimeLabel = [(UILabel *)cell.contentView viewWithTag:2];
    if (!endTimeLabel) {
        endTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(contentView_width-padding_right-label_width, y2, label_width, label_height)];
        endTimeLabel.tag = 2;
        endTimeLabel.font = [UIFont systemFontOfSize:13.0];
        [endTimeLabel setTextAlignment:NSTextAlignmentRight];
        endTimeLabel.textColor = [UIColor darkGrayColor];
        endTimeLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:endTimeLabel];
    }
    if ([array_departureArrivalTime count]>1)
    endTimeLabel.text = [NSString stringWithFormat:@"\U0001F553%@", [array_departureArrivalTime objectAtIndex:1]];
    
    
    //
    UIImageView *uIImageView_startStop = [(UIImageView *)cell.contentView viewWithTag:3];
    if (!uIImageView_startStop) {
        uIImageView_startStop = [[UIImageView alloc] initWithFrame:CGRectMake(padding_left,y3,label_height*132/293,label_height)];
        uIImageView_startStop.tag = 3;
        uIImageView_startStop.image=[UIImage imageNamed:@"unicode_start_stop.png"];
        [cell.contentView addSubview:uIImageView_startStop];
    }
    UIImageView *uIImageView_endStop = [(UIImageView *)cell.contentView viewWithTag:4];
    if (!uIImageView_endStop) {
        uIImageView_endStop = [[UIImageView alloc] initWithFrame:CGRectMake(contentView_width-padding_right-label_height*132/293,y3,label_height*132/293,label_height)];
        uIImageView_endStop.image=[UIImage imageNamed:@"unicode_end_stop.png"];
        uIImageView_endStop.tag = 4;
        [cell.contentView addSubview:uIImageView_endStop];
    }
    
    //    UILabel *startStopLabel = [(UILabel *)cell.contentView viewWithTag:3];
    //    if (!startStopLabel) {
    //        startStopLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding_left, y3, label_width, label_height)];
    //        startStopLabel.tag = 3;
    //        startStopLabel.text = @"\U0001F68F";
    //        startStopLabel.font = [UIFont systemFontOfSize:14.0];
    //        startStopLabel.backgroundColor = [UIColor clearColor];
    //        [cell.contentView addSubview:startStopLabel];
    //    }
    
    //    UILabel *endStopLabel = [(UILabel *)cell.contentView viewWithTag:4];
    //    if (!endStopLabel) {
    //        endStopLabel = [[UILabel alloc] initWithFrame:CGRectMake(contentView_width-padding_right-label_width, y3, label_width, label_height)];
    //        endStopLabel.tag = 4;
    //        endStopLabel.text = @"\U0001F68F";   //@"\U0001F6A9";
    //        endStopLabel.font = [UIFont systemFontOfSize:14.0];
    //        [endStopLabel setTextAlignment:NSTextAlignmentRight];
    //        endStopLabel.backgroundColor = [UIColor clearColor];
    //        [cell.contentView addSubview:endStopLabel];
    //    }
    
    UIView *viewGrey = [(UILabel *)cell.contentView viewWithTag:6];
    if (viewGrey) {
        [viewGrey removeFromSuperview];
    }
    UIView *viewGreen = [(UILabel *)cell.contentView viewWithTag:7];
    if (viewGreen) {
        [viewGreen removeFromSuperview];
    }
    UILabel *busLabel = [(UILabel *)cell.contentView viewWithTag:5];
    if (busLabel) {
        [busLabel removeFromSuperview];
    }
    if (num_stops!=0) {
        // Draw invalid
        viewGrey = [[UIView alloc] initWithFrame:CGRectMake(padding_left, y1, length1, 8)];
        viewGrey.tag = 6;
        viewGrey.backgroundColor = [UIColor lightGrayColor];
        [cell.contentView addSubview:viewGrey];
        // Draw Valid
        viewGreen = [[UIView alloc] initWithFrame:CGRectMake(padding_left+length1, y1, contentView_width-padding_left-padding_right-length1, 8)];
        viewGreen.tag = 7;
        viewGreen.backgroundColor = DefaultLighterGreen;
        [cell.contentView addSubview:viewGreen];
        
        busLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding_left+length1, y3, label_width, label_height)];
        busLabel.tag = 5;
        busLabel.text = @"\U0001F68C \U000021E2";
        busLabel.font = [UIFont systemFontOfSize:14.0];
        busLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:busLabel];
    } else {
        // Draw invalid
        viewGrey = [[UIView alloc] initWithFrame:CGRectMake(padding_left, y1, contentView_width-padding_left-padding_right, 8)];
        viewGrey.tag = 6;
        viewGrey.backgroundColor = [UIColor lightGrayColor];
        [cell.contentView addSubview:viewGrey];
    }
    
    UILabel *selectedStopLabel = [(UILabel *)cell.contentView viewWithTag:11];
    if (selectedStopLabel) {
        [selectedStopLabel removeFromSuperview];
    }
    UILabel *selectedStopLabel_time = [(UILabel *)cell.contentView viewWithTag:12];
    if (selectedStopLabel_time) {
        [selectedStopLabel_time removeFromSuperview];
    }
    
    if (map_selectedStop && [map_selectedStop objectForKey:@"stop_id"]) {
        NSInteger index_selectedStop = -1;
//        NSInteger num_stops = -1;
        NSArray *array_Stops = [[nSMDictionary_tripID_stops objectForKey:tripID] objectForKey:@"stops"];
        
        // Time
        NSTimeInterval nSTimeInterval=0;
        
        for (NSDictionary *map_stop in array_Stops) {
            if ([[map_stop objectForKey:@"stopId"] isEqualToString:[map_selectedStop objectForKey:@"stop_id"]]) {
                index_selectedStop = [[map_stop objectForKey:@"stopSequence"] integerValue];
//                num_stops = [[[array_Stops lastObject] objectForKey:@"stopSequence"] integerValue];
                
                nSTimeInterval = [[map_stop objectForKey:@"time"] integerValue];
            }
        }
        NSLog(@"518: %ld, %ld", (long)index_selectedStop, (long)num_stops);
        
        if (index_selectedStop>=0 && num_stops>0 && index_selectedStop<=num_stops) {
            float x_selectedStop = (contentView_width-padding_left-padding_right)*index_selectedStop/num_stops;
            selectedStopLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding_left+x_selectedStop, y3, label_width, label_height)];
            selectedStopLabel.tag = 11;
            selectedStopLabel.text = [NSString stringWithFormat:@"\U0001F6A9"];
            selectedStopLabel.font = [UIFont systemFontOfSize:14.0];
            selectedStopLabel.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:selectedStopLabel];
            
            
            NSDate *nSDate = [NSDate dateWithTimeIntervalSinceReferenceDate:nSTimeInterval];
            NSDateFormatter *dtFormatter=[[NSDateFormatter alloc]init];
            [dtFormatter setDateFormat:@"hh:mma"];
            if (nSTimeInterval!=0) {
                if ((padding_left+x_selectedStop-label_width/2+label_width*1.4)>contentView_width)
                selectedStopLabel_time = [[UILabel alloc] initWithFrame:CGRectMake(contentView_width-label_width*1.4, y2, label_width*1.4, label_height)];
                else
                selectedStopLabel_time = [[UILabel alloc] initWithFrame:CGRectMake(padding_left+x_selectedStop-label_width/2, y2, label_width*1.4, label_height)];
                selectedStopLabel_time.tag = 12;
                selectedStopLabel_time.text = [NSString stringWithFormat:@"\U0001F553%@", [dtFormatter stringFromDate:nSDate]];
                selectedStopLabel_time.font = [UIFont systemFontOfSize:14.0];
                selectedStopLabel_time.backgroundColor = TopBarRealtimeGoColor;
                selectedStopLabel_time.textColor = [UIColor whiteColor];
                [selectedStopLabel_time setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:selectedStopLabel_time];
            }
        } else {
            // show static data from database
            NSMutableDictionary *returnDic = [nSMDictionary_tripIDStopID_staticDic objectForKey:[tripID stringByAppendingString:[map_selectedStop objectForKey:@"stop_id"]]];
            if (returnDic==nil)
                returnDic = [appDelegate.dbManager getStaticTimeStringByTripID:tripID andStopID:[map_selectedStop objectForKey:@"stop_id"]];
            if (returnDic!=nil) {
                [nSMDictionary_tripIDStopID_staticDic setObject:returnDic forKey:[tripID stringByAppendingString:[map_selectedStop objectForKey:@"stop_id"]]];
                index_selectedStop = [[returnDic objectForKey:@"stop_sequence"] integerValue];
                NSLog(@" - 518: %ld, %ld", (long)index_selectedStop, (long)num_stops);
                float x_selectedStop = (contentView_width-padding_left-padding_right)*index_selectedStop/num_stops;
                selectedStopLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding_left+x_selectedStop, y3, label_width, label_height)];
                selectedStopLabel.tag = 11;
                selectedStopLabel.text = [NSString stringWithFormat:@"\U0001F6A9"];
                selectedStopLabel.font = [UIFont systemFontOfSize:14.0];
                selectedStopLabel.backgroundColor = [UIColor clearColor];
                [cell.contentView addSubview:selectedStopLabel];
                
                if ((padding_left+x_selectedStop-label_width/2+label_width*1.4)>contentView_width)
                    selectedStopLabel_time = [[UILabel alloc] initWithFrame:CGRectMake(contentView_width-label_width*1.4, y2, label_width*1.4, label_height)];
                else
                    selectedStopLabel_time = [[UILabel alloc] initWithFrame:CGRectMake(padding_left+x_selectedStop-label_width/2, y2, label_width*1.4, label_height)];
                selectedStopLabel_time.tag = 12;
                selectedStopLabel_time.text = [NSString stringWithFormat:@"\U0001F553%@", [returnDic objectForKey:@"departure_time"] ];
                selectedStopLabel_time.font = [UIFont systemFontOfSize:14.0];
                selectedStopLabel_time.backgroundColor = TopBarRealtimeGoColor;
                selectedStopLabel_time.textColor = [UIColor whiteColor];
                [selectedStopLabel_time setTextAlignment:NSTextAlignmentCenter];
                [cell.contentView addSubview:selectedStopLabel_time];
                
            }
            
        }
    }
    
    UIButton *uIButton_tripIndex = [(UIButton *)cell.contentView viewWithTag:10];
    [uIButton_tripIndex setTitle:[NSString stringWithFormat:@"Bus %ld", indexPath.row+1] forState:UIControlStateNormal];
    
//    cell.contentView.backgroundColor = [UIColor grayColor];
    
    return cell;
}

#pragma mark - AKPickerViewDataSource

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView
{
    if (self.titles)
    return [self.titles count];
    else
    return 0;
}

/*
 * AKPickerView now support images!
 *
 * Please comment '-pickerView:titleForItem:' entirely
 * and uncomment '-pickerView:imageForItem:' to see how it works.
 *
 */

- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item
{
    if (self.titles && [self.titles count]>item)
    return self.titles[item];
    else
    return @"";
}

/*
 - (UIImage *)pickerView:(AKPickerView *)pickerView imageForItem:(NSInteger)item
 {
	return [UIImage imageNamed:self.titles[item]];
 }
 */



-(UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0f);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

- (IBAction)didTapSelectRoute:(id)sender {
    if (self.cSAV_routeSelectionView.isHidden) {
        
        [self cSAnimationView_routePickerSetHidden:NO];
        [self.view bringSubviewToFront:self.cSAV_routeSelectionView];
        self.cSAV_selectedStopDetail.hidden = YES;
        map_selectedStop = nil;
        //        [self cSAnimationView_topInfoSetHidden:YES];
    } else {
        [self cSAnimationView_routePickerSetHidden:YES];
        //        [self cSAnimationView_topInfoSetHidden:NO];
    }
}

-(void)cSAnimationView_routePickerSetHidden:(BOOL)b {
    if (b) {
        [self.cSAV_routeSelectionView setHidden:YES];
        pickerView.hidden = NO;
        self.cSAV_tripDetailsView.hidden = NO;
        self.cSAV_tripDetailsView.type = CSAnimationTypeBounceLeft;
        self.cSAV_tripDetailsView.duration = 0.3;
        self.cSAV_tripDetailsView.delay = 0.0;
        [self.cSAV_tripDetailsView startCanvasAnimation];
        self.cSAV_tripDetailsView.alpha = 0.85;
    } else {
        self.cSAV_routeSelectionView.alpha=0;
        [self.cSAV_routeSelectionView setHidden:NO];
        self.cSAV_routeSelectionView.type = CSAnimationTypeBounceUp;
        self.cSAV_routeSelectionView.duration = 0.3;
        self.cSAV_routeSelectionView.delay = 0.2;
        [self.cSAV_routeSelectionView startCanvasAnimation];
        self.cSAV_routeSelectionView.alpha=1;
        pickerView.hidden = YES;
        self.cSAV_tripDetailsView.hidden = YES;
    }
}

- (IBAction)didTapRouteSelectionCancel:(id)sender {
    [self cSAnimationView_routePickerSetHidden:YES];
    //    [self cSAnimationView_topInfoSetHidden:NO];
    if (!allRouteId_sorted || [allRouteId_sorted count]<1 || selectedRoute) {
        return;
    }
    moveCameraToBound_int = 0;
    [self cSAnimationView_routePickerSetHidden:YES];
    selectedRoute = [NSString stringWithFormat:@"%@",[allRouteId_sorted objectAtIndex:0]];
    selectedTrip = @"";
    self.uILabel_topInfo.text = [NSString stringWithFormat:@"ROUTE %@", selectedRoute];
    
    NSMutableArray *arrayTripIDs = [nSMDictionary_routeID_tripID objectForKey:selectedRoute];
    if (arrayTripIDs)
    [self initialHeadsignPickerWithTripIDs: arrayTripIDs];
    
    [nSTimer_updateViewsByFeedUpdate invalidate];
    nSTimer_updateViewsByFeedUpdate=nil;
    nSTimer_updateViewsByFeedUpdate = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(updateViewsByFeedUpdate) userInfo:nil repeats:YES];
    [nSTimer_updateViewsByFeedUpdate fire];
    
}

- (IBAction)didTapRouteSelectionDone:(id)sender {
    map_selectedStop = nil;
    [self initialPickerView];
    if (!allRouteId_sorted || [allRouteId_sorted count]<1) {
        return;
    }
    self.cSAV_selectedStopDetail.hidden = YES;
    moveCameraToBound_int = 0;
    [self cSAnimationView_routePickerSetHidden:YES];
    selectedRoute = [NSString stringWithFormat:@"%@",[allRouteId_sorted objectAtIndex:[self.uIPickerView_routes selectedRowInComponent:0]]];
    selectedTrip = @"";
    self.uILabel_topInfo.text = [NSString stringWithFormat:@"ROUTE %@", selectedRoute];
    
    NSMutableArray *arrayTripIDs = [nSMDictionary_routeID_tripID objectForKey:selectedRoute];
//    NSLog(@"-->arrayTripIDs, %@", arrayTripIDs);
    [self initialHeadsignPickerWithTripIDs: arrayTripIDs];
    
    [nSTimer_updateViewsByFeedUpdate invalidate];
    nSTimer_updateViewsByFeedUpdate=nil;
    nSTimer_updateViewsByFeedUpdate = [NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(updateViewsByFeedUpdate) userInfo:nil repeats:YES];
    [nSTimer_updateViewsByFeedUpdate fire];
}

- (void)updateViewsByFeedUpdate {
    NSMutableArray *arrayTripIDs = [nSMDictionary_routeID_tripID objectForKey:selectedRoute];
    if (!arrayTripIDs)
    arrayTripIDs = [[NSMutableArray alloc] init];
    NSMutableArray *arrayTripIDsForSelectedHeadsign = [[NSMutableArray alloc] initWithCapacity:5];
    for (NSString *tripID in arrayTripIDs) {
        if ([nSMDictionary_tripID_stops objectForKey:tripID]) {
//            NSLog(@"TESTTT updateViewsByFeedUpdate:%@:%@", tripID, [nSMDictionary_tripID_stops objectForKey:tripID]);
            NSString *headsign = [[nSMDictionary_tripID_stops objectForKey:tripID] objectForKey:@"headsign"];
            if (headsign && headsign.length>0 && [headsign isEqualToString: self.titles[pickerView.selectedItem]]) {
                NSMutableArray *array_departureArrivalTime = [nSMDictionary_tripID_departureArrivalTime objectForKey:tripID];
                if (!array_departureArrivalTime) {
                    array_departureArrivalTime = [appDelegate.dbManager getDepartureAndArrivalTimeByTripID:tripID];
                    if (array_departureArrivalTime)
                    [nSMDictionary_tripID_departureArrivalTime setObject:array_departureArrivalTime forKey:tripID];
                }
                
                NSString *strTime = [[[array_departureArrivalTime objectAtIndex:1] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@":" withString:@""];
                NSDate *nSDate = [NSDate date];
                NSDateFormatter *dtFormatter=[[NSDateFormatter alloc]init];
                [dtFormatter setDateFormat:@"HH:mm"];
                [dtFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Central Time (US & Canada)"]];
                NSString *strTime2 = [[[dtFormatter stringFromDate:nSDate] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@":" withString:@""];
                
//                                NSLog(@"TMP:::TIME:::%d, %d", [strTime intValue], [strTime2 intValue]);
                if ([strTime intValue] < [strTime2 intValue]+5)
                continue;
                
                [arrayTripIDsForSelectedHeadsign addObject:tripID];
            } else {
                continue;
            }
        }
    }
//    NSLog(@"arrayTripIDsForSelectedHeadsign:::%lu", (unsigned long)[arrayTripIDsForSelectedHeadsign count]);
    if ([arrayTripIDsForSelectedHeadsign count]>0) {
        allTripId_sorted = [self sortTripIDsbyTimeAtDepartureTime:arrayTripIDsForSelectedHeadsign];
        if ([selectedTrip isEqualToString:@""] || ![allTripId_sorted containsObject:selectedTrip]) {
            selectedTrip = [allTripId_sorted objectAtIndex:0];
        }
        [self showPathForTripID: selectedTrip];
        [self showStopsForTripID: selectedTrip];
        for (NSString *tripID in allTripId_sorted) {
//            if (![tripID isEqualToString:selectedTrip])
            [self getMaxInValidAndValidNumForTripID:tripID];
        }
        
        [self showBusLocationForTripIDs];
    }
    [self.uITableView_tripDetails reloadData];
}

- (NSMutableArray *)sortTripIDsbyTimeAtDepartureTime: (NSMutableArray*)tripIDs {
    NSMutableArray *array_tmp = [[NSMutableArray alloc] init];
    for (NSString *tripID in tripIDs) {
        NSMutableDictionary *dictionary_tmp = [[NSMutableDictionary alloc] init];
        NSMutableArray *array_departureArrivalTime = [nSMDictionary_tripID_departureArrivalTime objectForKey:tripID];
        if (!array_departureArrivalTime) {
            array_departureArrivalTime = [appDelegate.dbManager getDepartureAndArrivalTimeByTripID:tripID];
            [nSMDictionary_tripID_departureArrivalTime setObject:array_departureArrivalTime forKey:tripID];
        }
        [dictionary_tmp setObject:[array_departureArrivalTime objectAtIndex:0] forKey:@"departureTime"];
        [dictionary_tmp setObject:tripID forKey:@"tripID"];
        [array_tmp addObject:dictionary_tmp];
    }
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"departureTime"
                                                                 ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [array_tmp sortedArrayUsingDescriptors:sortDescriptors];
    
    NSMutableArray *array_return = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *dictionary_tmp in sortedArray) {
        [array_return addObject:[dictionary_tmp objectForKey:@"tripID" ]];
    }
    return array_return;
}

- (void)showBusLocationForTripIDs {
    for (GMSMarker *marker_bus in array_busMarkers) {
        marker_bus.map=nil;
    }
    array_busMarkers = [[NSMutableArray alloc] init];
    for (NSString *tripID in allTripId_sorted) {
        NSMutableDictionary *nSMDictionary_bus = [nSMDictionary_tripID_busLocation objectForKey:tripID];
//                NSLog(@"TMP13:::%@",nSMDictionary_bus);
        if (!nSMDictionary_bus)
        return;
        CLLocationCoordinate2D bus_position = CLLocationCoordinate2DMake([[nSMDictionary_bus objectForKey:@"latitude"] floatValue], [[nSMDictionary_bus objectForKey:@"longitude"] floatValue]);
        GMSMarker *bus_marker = [GMSMarker markerWithPosition:bus_position];
        if ([tripID isEqualToString:selectedTrip])
        bus_marker.icon = [UIImage imageNamed:@"bus_marker_003@2x.png"];
        else {
            continue;
            //            bus_marker.icon = [UIImage imageNamed:@"bus_marker_gray@2x.png"];
        }
        //    bus_marker.userData = busTripId;
        bus_marker.map = self.mapView;
        bus_marker.zIndex = 11;
        [array_busMarkers addObject:bus_marker];
    }
    
    
}

- (void)getMaxInValidAndValidNumForTripID: (NSString *)tripID {
    
    if (![nSMDictionary_tripID_stops objectForKey:tripID])
    return;
    NSMutableArray *array_stops = [[nSMDictionary_tripID_stops objectForKey:tripID] objectForKey:@"stops"];
    if ([array_stops count]<1)
    return;
    NSInteger max_invalid_stop_index = [[[array_stops objectAtIndex:0] objectForKey:@"stopSequence"] integerValue]-1;
    NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
    for (NSMutableDictionary *map_stop in array_stops) {
        if ([[map_stop objectForKey:@"time"] longValue]<100)
        continue;
        if ([[map_stop objectForKey:@"time"] longValue] <timeInMiliseconds) {
            max_invalid_stop_index = [[map_stop objectForKey:@"stopSequence"] integerValue];
        }
    }
    [[nSMDictionary_tripID_stops objectForKey:tripID] setObject:[NSNumber numberWithInteger:max_invalid_stop_index] forKey: @"maxInvalid"];
    
    // check if number of stops for the tripID is already cached.
    if ([nSMDictionary_tripID_numStops objectForKey:tripID]) {
    } else {
        NSInteger valueFromRealtime = [[[array_stops lastObject] objectForKey:@"stopSequence"] integerValue];
        NSInteger valueFromStatic = [appDelegate.dbManager getNumStopsByTripID: tripID];
//        NSLog(@"452: %@, %ld, %ld", tripID, (long)valueFromRealtime, (long)valueFromStatic);
        if (valueFromRealtime < valueFromStatic) {
            [nSMDictionary_tripID_numStops setObject:[NSNumber numberWithInteger:valueFromStatic] forKey: tripID];
        } else {
            [nSMDictionary_tripID_numStops setObject:[NSNumber numberWithInteger:valueFromRealtime] forKey: tripID];
        }
//        NSLog(@"507: %@", nSMDictionary_tripID_numStops);
    }
    
    [[nSMDictionary_tripID_stops objectForKey:tripID] setObject:[NSNumber numberWithInteger:[[nSMDictionary_tripID_numStops objectForKey:tripID] integerValue]] forKey: @"maxValid"];
    
    
}

- (void)showStopsForTripID: (NSString *)tripID {
    
    //    [nSTimer_updateViewsByFeedUpdate invalidate];
    //    nSTimer_updateViewsByFeedUpdate=nil;
    //}
    //
    //- (void)viewDidAppear:(BOOL)animated {
    //    [super viewDidAppear:animated];
    //
    //    nSTimer_realtimeFeedUpdate = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(realtimeFeedUpdate) userInfo:nil repeats:YES];
    ////    [nSTimer_realtimeFeedUpdate fire];
    //    [nSTimer_flicker_stops invalidate];
    //    nSTimer_flicker_stops=nil;
    
    for (GMSMarker *marker_busStop in array_busStopMarkers) {
        marker_busStop.map=nil;
    }
    
    // Draw stops for trips
    UIImage *img_grey = [UIImage imageNamed:@"busStopWithTime_gray.png"];
    UIImage *img_green = [UIImage imageNamed:@"busStopWithTime_green.png"];
    UIImage *img_purple = [UIImage imageNamed:@"busStopWithTime_purple.png"];
    
    NSArray *stops = [nSMDictionary_tripID_staticStops objectForKey:tripID];
    if (!stops) {
        stops = [appDelegate.dbManager getStopsByTripID:tripID];
        if (!stops)
        return;
        [nSMDictionary_tripID_staticStops setObject:stops forKey:tripID];
    }
    
    NSMutableArray *array_stops = [[nSMDictionary_tripID_stops objectForKey:tripID] objectForKey:@"stops"];
    NSInteger max_invalid_stop_index = [[[array_stops objectAtIndex:0] objectForKey:@"stopSequence"] integerValue]-1;
    NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
    for (NSMutableDictionary *map_stop in array_stops) {
        if ([[map_stop objectForKey:@"time"] longValue]<100)
        continue;
        if ([[map_stop objectForKey:@"time"] longValue] <timeInMiliseconds) {
            max_invalid_stop_index = [[map_stop objectForKey:@"stopSequence"] integerValue];
        }
    }
    [[nSMDictionary_tripID_stops objectForKey:tripID] setObject:[NSNumber numberWithInteger:max_invalid_stop_index] forKey: @"maxInvalid"];
    [[nSMDictionary_tripID_stops objectForKey:tripID] setObject:[NSNumber numberWithInteger:[[[array_stops lastObject] objectForKey:@"stopSequence"] integerValue]] forKey: @"maxValid"];
    
    // Find nearest bus stop
    GMSMarker *nearest_busStop = nil;
    float nearest_distance = -1;
    for (NSDictionary *stop_one in stops) {
        GMSMarker *marker_busStop = [[GMSMarker alloc] init];
        marker_busStop.title = @"";
        self.uILabel_busStopMarker_stopId.text = [NSString stringWithFormat:@"%@", [stop_one objectForKey:@"stop_sequence"]];
        
        
        marker_busStop.userData = stop_one;
        
        // add trip id to userData
        [marker_busStop.userData setValue:tripID forKey:@"trip_id"];
        
        NSInteger index_stop = [stops indexOfObject:stop_one ];
        if ((int)index_stop==0)
        marker_busStop.icon = [UIImage imageNamed:@"greenmarker@2x.png"];
        else if ((int)index_stop==([stops count]-1))
        marker_busStop.icon = [UIImage imageNamed:@"redmarker@2x.png"];
        else {
            //            marker_busStop.icon = [UIImage imageNamed:@"yellowmarker_small@2x.png"];
            if ([[stop_one objectForKey:@"stop_sequence"] integerValue]>max_invalid_stop_index) {
                [self.uIImageView_stopIcon setImage:img_green];
                marker_busStop.icon = [UIImage imageNamed:@"stopMarker_green.png"];
            } else {
                [self.uIImageView_stopIcon setImage:img_grey];
                marker_busStop.icon = [UIImage imageNamed:@"stopMarker_gray.png"];
            }
            if ([[stop_one objectForKey:@"stop_id"] isEqualToString:[map_selectedStop objectForKey:@"stop_id"]]) {
                [self.uIImageView_stopIcon setImage:img_purple];
                marker_busStop.icon = [UIImage imageNamed:@"stopMarker_purple.png"];
            }
        }
        marker_busStop.position = CLLocationCoordinate2DMake([[stop_one objectForKey:@"stop_lat"] doubleValue], [[stop_one objectForKey:@"stop_lon"] doubleValue]);
        marker_busStop.map = self.mapView;
        marker_busStop.zIndex = 10;
        
        // calculate distance
        CLLocation *stopLocation = [[CLLocation alloc] initWithLatitude:[[stop_one objectForKey:@"stop_lat"] doubleValue] longitude:[[stop_one objectForKey:@"stop_lon"] doubleValue]];
        CLLocation *currentLocation = self.locationManager.location;
        float distance = [stopLocation distanceFromLocation:currentLocation];
        if (nearest_distance<0 || distance<nearest_distance) {
            nearest_distance = distance;
            nearest_busStop = marker_busStop;
        }
        
        [array_busStopMarkers addObject:marker_busStop];
        
        // Stop name label marker
        if (flag_busNameShown) {
            GMSMarker *marker_busStop = [[GMSMarker alloc] init];
            marker_busStop.title = @"";
            self.uILabel_stopName.hidden = NO;
            self.uILabel_stopName.text = [stop_one objectForKey:@"stop_name"];
            marker_busStop.icon = [self imageWithView: self.uIView_busStopMarker];
            marker_busStop.userData = stop_one;
            marker_busStop.position = CLLocationCoordinate2DMake([[stop_one objectForKey:@"stop_lat"] doubleValue], [[stop_one objectForKey:@"stop_lon"] doubleValue]);
            marker_busStop.map = self.mapView;
            marker_busStop.zIndex = 10;
            
            [array_busStopMarkers addObject:marker_busStop];
        } else {
            
        }
    }
    
    // select the nearest bus stop
    NSLog(@"1137:%@", map_selectedStop);
    if (nearest_busStop!=nil) {
        if (map_selectedStop==nil)
            [self mapView:self.mapView didTapMarker:nearest_busStop];
        
//        NSLog(@"1107:%@",nearest_busStop.userData);
//        NSLog(@"1108:%f",nearest_distance);
//        [self autoSelectNearestStop:self.mapView didTapMarker:nearest_busStop];
//        [self mapView:self.mapView didTapMarker:nearest_busStop];
    }
}

//-(BOOL)autoSelectNearestStop:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
//    if ((marker.userData && map_selectedStop==nil) || (map_selectedStop!=nil && ![[map_selectedStop objectForKey:@"stop_id"] isEqualToString:[marker.userData objectForKey:@"stop_id"]])) {
//        map_selectedStop = marker.userData;
//        [nSTimer_updateViewsByFeedUpdate fire];
//        if ([map_selectedStop objectForKey:@"stop_sequence"] && [map_selectedStop objectForKey:@"stop_name"]) {
//            self.uILabel_selectedStop_detail.text = [NSString stringWithFormat:@"%@. %@", [map_selectedStop objectForKey:@"stop_sequence"], [map_selectedStop objectForKey:@"stop_name"] ];
//            [self.cSAV_mapView bringSubviewToFront: self.cSAV_selectedStopDetail];
//            self.cSAV_selectedStopDetail.hidden = NO;
//            self.cSAV_selectedStopDetail.type = CSAnimationTypeFadeIn;
//            self.cSAV_selectedStopDetail.duration = 0.3;
//            self.cSAV_selectedStopDetail.delay = 0.0;
//            [self.cSAV_selectedStopDetail startCanvasAnimation];
//            self.cSAV_selectedStopDetail.alpha = 0.85;
//        }
//    }
//    return YES;
//}

- (void)showPathForTripID: (NSString *)tripID {
    
    [self.mapView clear];
    
    // Draw path for trip
    NSArray *shapes = [map_tripID_pathCoordinates objectForKey:tripID];
    if (!shapes) {
        shapes =[appDelegate.dbManager getShapeArrayFromTripID:tripID];
        if (!shapes)
        return;
        [map_tripID_pathCoordinates setObject:shapes forKey:tripID];
    }
    GMSMutablePath *path = [GMSMutablePath path];
    for (NSArray *coor in shapes) {
        [path addCoordinate:CLLocationCoordinate2DMake([coor[0] doubleValue], [coor[1] doubleValue])];
    }
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    NSMutableArray *colorArray = [[NSMutableArray alloc] init];
    [colorArray addObject:UIColorFromRGB(0xF16745)];
    [colorArray addObject:UIColorFromRGB(0x7BC8A4)];
    [colorArray addObject:UIColorFromRGB(0x4CC3D9)];
    [colorArray addObject:UIColorFromRGB(0x93648D)];
    [colorArray addObject:UIColorFromRGB(0x7BC8A4)];
    polyline.strokeColor = [colorArray objectAtIndex:[selectedRoute integerValue]%[colorArray count]];
    polyline.strokeWidth = 6.f;
    polyline.geodesic = YES;
    polyline.map = self.mapView;
    
    if (moveCameraToBound_int++<1) {
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
        GMSCameraPosition *camera = [self.mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(135, 35, 35, 35)];
        [self.mapView animateToCameraPosition:camera];
    }
}

- (void)initialHeadsignPickerWithTripIDs: (NSMutableArray *) arrayTripIDs{
    
    self.titles = [[NSMutableArray alloc] initWithCapacity:2];
    
    if (!arrayTripIDs)
    return;
    NSLog(@"-->arrayTripIDs:%@", arrayTripIDs);
    for (NSString *tripID in arrayTripIDs) {
//        NSLog(@"-->[nSMDictionary_tripID_stops objectForKey:tripID]:%@", [nSMDictionary_tripID_stops allKeys]);
        NSString *headsign = [[nSMDictionary_tripID_stops objectForKey:tripID] objectForKey:@"headsign"];
        if (headsign && headsign.length>0) {
            [self.titles addObject:headsign];
        } else {
            continue;
        }
    }
    self.titles = [NSMutableArray arrayWithArray: [[[NSSet setWithArray:self.titles] allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]] ];
    [pickerView reloadData];
    
}
- (IBAction)didTapHideSelectedStopDetail:(id)sender {
    map_selectedStop = nil;
    self.cSAV_selectedStopDetail.hidden = YES;
    [nSTimer_updateViewsByFeedUpdate fire];
}
@end
