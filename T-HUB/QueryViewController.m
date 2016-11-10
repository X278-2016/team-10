//
//  QueryViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 10/7/15.
//  Copyright © 2015 Fangzhou Sun. All rights reserved.
//

#import "QueryViewController.h"
#import "AppDelegate.h"
#import "ColorConstants.h"
#import "AFNetworking.h"
//#import "ProtocolBuffers.h"
#import <ProtocolBuffers/ProtocolBuffers.h>
#import "GtfsRealtime.pb.h"
#import "JSONParser.h"
#import <QuartzCore/QuartzCore.h>

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]

@interface QueryViewController () {
    AppDelegate *appDelegate;
    NSMutableDictionary *allRoutes;
    NSArray *allRouteId_sorted;
    NSString *selectedRoute;
    NSString *selectedTrip;
    NSArray *array_tripIds;
    NSMutableDictionary *map_coorForStopId;
    NSMutableArray *array_busStopMarkers;
    NSMutableArray *array_busMarkers;
    NSTimer *uIRefreshTimer;
    BOOL moveCameraToBound;
    int moveCameraToBound_int;
}

@property (strong, nonatomic) GMSMapView *mapView;

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation QueryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // AppDelegate
    appDelegate = ((AppDelegate*)[[UIApplication sharedApplication]delegate]);
    
    allRoutes = [[NSMutableDictionary alloc] init];
    [self getTripUpdate];
    self.cSAnimationView_routePicker.alpha=0;
    self.cSAnimationView_topInfo.alpha = 0;
    self.cSAnimationView_previousAndNextTrips.alpha = 0;
    //    [self.uIView_busStopMarker setHidden:YES];
    map_coorForStopId = [[NSMutableDictionary alloc] init];
    
    [[self.uIButton_previousTrip layer] setCornerRadius:5.0f];
    [[self.uIButton_previousTrip layer] setMasksToBounds:YES];
    [[self.uIButton_previousTrip layer] setBorderWidth:1.0f];
    [[self.uIButton_previousTrip layer] setBorderColor:DefaultGreen.CGColor];
    
    [[self.uIButton_nextTrip layer] setCornerRadius:5.0f];
    [[self.uIButton_nextTrip layer] setMasksToBounds:YES];
    [[self.uIButton_nextTrip layer] setBorderWidth:1.0f];
    [[self.uIButton_nextTrip layer] setBorderColor:DefaultGreen.CGColor];
    
//    moveCameraToBound = YES;
    moveCameraToBound_int=0;
    
    [self getCurrentLocation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self initMap];
    [self cSAnimationView_routePickerSetHidden:NO];
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
    self.mapView = [GMSMapView mapWithFrame:self.cSAnimationView_content.bounds camera:camera];
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    self.mapView.indoorEnabled = NO;
    //    [self.CSAnimationView_Map addSubview:self.mapView];
    [self.cSAnimationView_content addSubview:self.mapView];
    [self.cSAnimationView_content bringSubviewToFront:self.cSAnimationView_routePicker];
    [self.cSAnimationView_content bringSubviewToFront:self.cSAnimationView_topInfo];
    [self.cSAnimationView_content bringSubviewToFront:self.cSAnimationView_previousAndNextTrips];
    self.uIView_busStopMarker.alpha=1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

//- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
//    
//    if (component == 0) {
//        NSLog(@"TEST::: didSelectRow:::%ld", (long)row);
//        [self.uIPickerView_routePicker reloadComponent:1];
//    }
//}

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    if (component==0) {
        return [allRouteId_sorted count];
    } else {
        return [allRouteId_sorted count];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    if (component==0) {
        return [allRouteId_sorted objectAtIndex:row];
    } else {
        
        return [allRouteId_sorted objectAtIndex:row];
    }
}

-(void)getTripUpdate {
    
    NSURL *URL=[NSURL URLWithString: tripUpdatesURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
        //        NSLog(@"213feedMessage.entity: %@ ", feedMessage.entity);
        if ([feedMessage.entity count]==0)
            return;
        for (FeedEntity *feedEntity in feedMessage.entity) {
            NSString *routeId = feedEntity.tripUpdate.trip.routeId;
            NSString *tripId = feedEntity.tripUpdate.trip.tripId;
            //            NSLog(@"TEST::: %@-%@-%@",routeId,tripId, feedEntity.tripUpdate.stopTimeUpdate);
            if (feedEntity.tripUpdate.stopTimeUpdate) {
                NSMutableDictionary *trips = [allRoutes objectForKey: routeId];
                if (trips) {
                    [trips setObject:feedEntity.tripUpdate.stopTimeUpdate forKey:tripId];
                    [allRoutes setObject:trips forKey:routeId];
                } else {
                    NSMutableDictionary *dicTrips = [[NSMutableDictionary alloc] init];
                    [dicTrips setObject:feedEntity.tripUpdate.stopTimeUpdate forKey:tripId];
                    [allRoutes setObject:dicTrips forKey:routeId];
                }
            }
        }
        allRouteId_sorted = [allRoutes.allKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
        [self.uIPickerView_routePicker reloadAllComponents];
        if (!selectedRoute || selectedRoute.length==0) {
            selectedRoute = [allRouteId_sorted objectAtIndex:0];
            selectedTrip = @"";
            [self.uIPickerView_routePicker selectRow:0 inComponent:0 animated:YES];
            self.uILabel_topInfo.text = [NSString stringWithFormat:@"Showing Route %@", selectedRoute];
        }
        
        [self showRouteOnMap];
        [self showBusesForRoute];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
}


- (IBAction)didTapGoBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapSelectRoute:(id)sender {
    if (self.cSAnimationView_routePicker.isHidden) {
        
        [self cSAnimationView_routePickerSetHidden:NO];
        [self cSAnimationView_topInfoSetHidden:YES];
    } else {
        [self cSAnimationView_routePickerSetHidden:YES];
        [self cSAnimationView_topInfoSetHidden:NO];
    }
}

- (IBAction)didTapCancelInView:(id)sender {
    [self cSAnimationView_routePickerSetHidden:YES];
    [self cSAnimationView_topInfoSetHidden:NO];
}

- (IBAction)didTapDoneInView:(id)sender {
//    moveCameraToBound = YES;
    moveCameraToBound_int=0;
    [self cSAnimationView_routePickerSetHidden:YES];
    [self cSAnimationView_topInfoSetHidden:NO];
    selectedRoute = [allRouteId_sorted objectAtIndex:[self.uIPickerView_routePicker selectedRowInComponent:0]];
    selectedTrip = @"";
    self.uILabel_topInfo.text = [NSString stringWithFormat:@"Showing Route %@", selectedRoute];
}

-(void)cSAnimationView_routePickerSetHidden:(BOOL)b {
    if (b) {
        [self.cSAnimationView_routePicker setHidden:YES];
    } else {
        self.cSAnimationView_routePicker.alpha=0;
        [self.cSAnimationView_routePicker setHidden:NO];
        self.cSAnimationView_routePicker.type = CSAnimationTypeBounceUp;
        self.cSAnimationView_routePicker.duration = 0.3;
        self.cSAnimationView_routePicker.delay = 0.0;
        [self.cSAnimationView_routePicker startCanvasAnimation];
        self.cSAnimationView_routePicker.alpha=1;
    }
}

-(void)cSAnimationView_topInfoSetHidden:(BOOL)b {
    if (b) {
        [self.cSAnimationView_topInfo setHidden:YES];
        [self.cSAnimationView_previousAndNextTrips setHidden:YES];
        [self.mapView clear];
        [uIRefreshTimer invalidate];
        uIRefreshTimer=nil;
    } else {
        self.cSAnimationView_topInfo.alpha=0;
        [self.cSAnimationView_topInfo setHidden:NO];
        self.cSAnimationView_topInfo.type = CSAnimationTypeBounceLeft;
        self.cSAnimationView_topInfo.duration = 0.3;
        self.cSAnimationView_topInfo.delay = 0.0;
        [self.cSAnimationView_topInfo startCanvasAnimation];
        self.cSAnimationView_topInfo.alpha=0.8;
        
        self.cSAnimationView_previousAndNextTrips.alpha=0;
        [self.cSAnimationView_previousAndNextTrips setHidden:NO];
        self.cSAnimationView_previousAndNextTrips.type = CSAnimationTypeBounceLeft;
        self.cSAnimationView_previousAndNextTrips.duration = 0.3;
        self.cSAnimationView_previousAndNextTrips.delay = 0.3;
        [self.cSAnimationView_previousAndNextTrips startCanvasAnimation];
        self.cSAnimationView_previousAndNextTrips.alpha=0.8;
        
        [self refreshMarkers];
        [uIRefreshTimer invalidate];
        uIRefreshTimer=nil;
        uIRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(refreshMarkers) userInfo:nil repeats:YES];
    }
}

-(void)showRouteOnMap {
    [self.mapView clear];
    array_busStopMarkers = [[NSMutableArray alloc] init];
    
    
    NSMutableDictionary *map_trips = [allRoutes objectForKey:selectedRoute];
    if (!selectedTrip || selectedTrip.length==0) {
        selectedTrip = map_trips.allKeys[0];
        if (!selectedTrip)
            return;
    }
    
    array_tripIds = map_trips.allKeys;
    
    NSArray *array_shape = [appDelegate.dbManager getShapeArrayFromTripID:selectedTrip];
    
    GMSMutablePath *path = [GMSMutablePath path];
    
    for (NSArray *coor in array_shape) {
        [path addCoordinate:CLLocationCoordinate2DMake([coor[0] doubleValue], [coor[1] doubleValue])];
    }
    
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    
    NSMutableArray *colorArray = [[NSMutableArray alloc] init];
    [colorArray addObject:UIColorFromRGB(0xF16745)];
    [colorArray addObject:UIColorFromRGB(0x7BC8A4)];
    [colorArray addObject:UIColorFromRGB(0x4CC3D9)];
    [colorArray addObject:UIColorFromRGB(0x93648D)];
    [colorArray addObject:UIColorFromRGB(0x7BC8A4)];
    polyline.strokeColor = [colorArray objectAtIndex:[selectedTrip intValue]%[colorArray count]];
    polyline.strokeWidth = 6.f;
    polyline.geodesic = YES;
    polyline.map = self.mapView;
    
    if (moveCameraToBound_int++<1) {
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
        GMSCameraPosition *camera = [self.mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(100, 35, 35, 35)];
        [self.mapView animateToCameraPosition:camera];
    }
    
    for (TripUpdateStopTimeUpdate *tripUpdateStopTimeUpdate in [map_trips objectForKey:selectedTrip]) {
//        NSLog(@"TEST::: %@", tripUpdateStopTimeUpdate);
        NSArray *coor = [map_coorForStopId objectForKey:tripUpdateStopTimeUpdate.stopId];
        if (coor==nil) {
            coor = [appDelegate.dbManager getCoorFromStopId: tripUpdateStopTimeUpdate.stopId];
        }
        NSTimeInterval nSTimeInterval = tripUpdateStopTimeUpdate.departure.time;
        NSDate *nSDate = [NSDate dateWithTimeIntervalSinceReferenceDate:nSTimeInterval];
        NSDateFormatter *dtFormatter=[[NSDateFormatter alloc]init];
        [dtFormatter setDateFormat:@"hh:mma"];
        
        GMSMarker *marker_busStop = [[GMSMarker alloc] init];
        marker_busStop.title = @"";
        if (nSTimeInterval!=0)
            self.uILabel_busStopMarker_expectedTime.text = [dtFormatter stringFromDate:nSDate];
        else
            self.uILabel_busStopMarker_expectedTime.text = @"END";
        self.uILabel_busStopMarker_stopId.text = [NSString stringWithFormat:@"%u", (unsigned int)tripUpdateStopTimeUpdate.stopSequence];
        
        marker_busStop.icon = [self imageWithView: self.uIView_busStopMarker];
        marker_busStop.position = CLLocationCoordinate2DMake([coor[0] doubleValue], [coor[1] doubleValue]);
        marker_busStop.map = self.mapView;
        marker_busStop.zIndex = 10;
        [array_busStopMarkers addObject:marker_busStop];
    }
    
}

-(void)refreshMarkers {
    for (GMSMarker *marker_busStop in array_busStopMarkers) {
        marker_busStop.map=nil;
    }
    for (GMSMarker *marker_bus in array_busMarkers) {
        marker_bus.map=nil;
    }
    
    [self getTripUpdate];
//    moveCameraToBound = NO;
//    [self showRouteOnMap];
//    [self showBusesForRoute];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        for (GMSMarker *marker_busStop in array_busStopMarkers) {
//            marker_busStop.map=self.mapView;
//        }
//        for (GMSMarker *marker_bus in array_busMarkers) {
//            marker_bus.map=self.mapView;
//        }
    });
}

- (void)showBusesForRoute{
    array_busMarkers = [[NSMutableArray alloc] init];
    
    NSURL *URL = [NSURL URLWithString: vehiclePositionsURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    //    NSString *fileName = [URL lastPathComponent];
    
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // here we must create NSData object with received data...
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
        for (FeedEntity *feedEntity in feedMessage.entity) {
            NSString *busTripId = feedEntity.vehicle.trip.tripId;
            
            BOOL isSameRoute=NO;
            for (NSString *tripId in array_tripIds) {
                if ([tripId isEqualToString:busTripId])
                    isSameRoute=YES;
            }
            if (isSameRoute) {
                CLLocationCoordinate2D bus_position = CLLocationCoordinate2DMake(feedEntity.vehicle.position.latitude, feedEntity.vehicle.position.longitude);
                GMSMarker *bus_marker = [GMSMarker markerWithPosition:bus_position];
                if ([busTripId isEqualToString:selectedTrip])
                    bus_marker.icon = [UIImage imageNamed:@"bus_marker_002@2x.png"];
                else
                    bus_marker.icon = [UIImage imageNamed:@"bus_marker_gray@2x.png"];
                bus_marker.userData = busTripId;
                bus_marker.map = self.mapView;
                bus_marker.zIndex = 11;
                [array_busMarkers addObject:bus_marker];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
    
}

-(BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    
    NSString *trip_id = marker.userData;
    if (trip_id) {
        selectedTrip = trip_id;
        [self refreshMarkers];
        [uIRefreshTimer invalidate];
        uIRefreshTimer=nil;
        uIRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(refreshMarkers) userInfo:nil repeats:YES];
    }
    return YES;
}



-(UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0f);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

- (IBAction)didTapPreviousTrip:(id)sender {
//    moveCameraToBound = YES;
    moveCameraToBound_int = 0;
    int i=0;
    for (NSString *tripId in array_tripIds) {
        if ([tripId isEqualToString:selectedTrip])
            break;
        i++;
    }
    selectedTrip = array_tripIds[(--i)%([array_tripIds count])];
    [self cSAnimationView_topInfoSetHidden:NO];
}
- (IBAction)didTapNextTrip:(id)sender {
//    moveCameraToBound = YES;
    moveCameraToBound_int = 0;
    int i=0;
    for (NSString *tripId in array_tripIds) {
        if ([tripId isEqualToString:selectedTrip])
            break;
        i++;
    }
    selectedTrip = array_tripIds[(++i)%([array_tripIds count])];
    [self cSAnimationView_topInfoSetHidden:NO];
}
@end
