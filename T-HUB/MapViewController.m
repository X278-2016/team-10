//
//  MapViewController.m
//  GCTC2
//
//  Created by Fangzhou Sun on 3/23/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "MapViewController.h"
#import "ColorConstants.h"
#import <sqlite3.h>
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "StatusView.h"
#import "BusAnnotationView.h"

@interface MapViewController () {
//    NSTimer *realtimeUpdateTimer;
    NSMutableArray *routeScrollArray;
    NSMutableDictionary *selectedRouteDic;
    
    NSMutableArray *busMarkers;
    
    NSMutableDictionary *savedAgenda;
    
    StatusView *statusView;
}

@property (strong, nonatomic) GMSMapView *mapView;

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [self startAnimationToFadeEverything];
    
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self initMap];
    [self initScroll];
    
    
    [self startAnimation];
    
}

- (void)initMap {
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:42.359879 longitude:-71.058616 zoom:14];
    self.mapView = [GMSMapView mapWithFrame:self.CSAnimationView_map.bounds camera:camera];
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    [self.CSAnimationView_map addSubview:self.mapView];
    
    [self showSelectedRoute];
    
    //    if ([CLLocationManager locationServicesEnabled]) {
    //        NSLog(@"Location services are enabled");
    //        self.locationManager = [[CLLocationManager alloc] init];
    //        self.locationManager.delegate = self;
    //        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //        [self.locationManager startUpdatingLocation];
    //    } else {
    //        NSLog(@"Location services are not enabled");
    //    }
    
}

- (void)showSelectedRoute {
    NSMutableArray *colorArray = [[NSMutableArray alloc] init];
    //    [colorArray addObject:[UIColor colorWithRed:219/255.0 green:51/255.0 blue:64/255.0 alpha:1]];
    [colorArray addObject:[UIColor colorWithRed:40/255.0 green:171/255.0 blue:227/255.0 alpha:1]];
    [colorArray addObject:[UIColor colorWithRed:31/255.0 green:218/255.0 blue:154/255.0 alpha:1]];
    
    [self.mapView clear];
    
    int colorIndex = 0;
    
    int breakFlag = 0;
    
    for (int i=0; i<=[[self.route_dic objectForKey:@"routes"] count]; i++) {
        
        if (i==(int)self.selected_route_number) {
            i++;
        }
        if (i==[[self.route_dic objectForKey:@"routes"] count]) {
            i=(int)self.selected_route_number;
            breakFlag = 1;
        }
        
        NSMutableDictionary *leg_array = [[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"legs"] objectAtIndex:0];
        
        // Markers
        GMSMarker *tomarker =  [[GMSMarker alloc] init];
        tomarker.map = self.mapView;
        tomarker.icon = [UIImage imageNamed:@"redmarker@2x.png"];
        tomarker.position = CLLocationCoordinate2DMake([[[[leg_array objectForKey:@"end_location"] allValues] objectAtIndex:0] floatValue],[[[[leg_array objectForKey:@"end_location"] allValues] objectAtIndex:1] floatValue]);
        
        // Markers
        GMSMarker *frommarker =  [[GMSMarker alloc] init];
        frommarker.map = self.mapView;
        frommarker.icon = [UIImage imageNamed:@"greenmarker@2x.png"];
        frommarker.position = CLLocationCoordinate2DMake([[[[leg_array objectForKey:@"start_location"] allValues] objectAtIndex:0] floatValue],[[[[leg_array objectForKey:@"start_location"] allValues] objectAtIndex:1] floatValue]);
        
        CLLocationCoordinate2D coordinateSouthWest = CLLocationCoordinate2DMake(
            [[[[[[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"bounds"] allValues] objectAtIndex:0] allValues] objectAtIndex:0] doubleValue],
            [[[[[[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"bounds"] allValues] objectAtIndex:1] allValues] objectAtIndex:0] doubleValue]
             );
        CLLocationCoordinate2D coordinateNorthEast = CLLocationCoordinate2DMake(
            [[[[[[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"bounds"] allValues] objectAtIndex:0] allValues] objectAtIndex:1] doubleValue],
            [[[[[[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"bounds"] allValues] objectAtIndex:1] allValues] objectAtIndex:1] doubleValue]
            );
                                                                                       
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:coordinateSouthWest coordinate:coordinateNorthEast];
        
        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds]];
        
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
                    [path addCoordinate:CLLocationCoordinate2DMake([[[onepath allValues] objectAtIndex:0] doubleValue], [[[onepath allValues] objectAtIndex:1] doubleValue])];
                }
                
                GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
                
                if (i==self.selected_route_number) {
                    polyline.strokeColor = [UIColor blackColor];
                    polyline.strokeWidth = 6.f;
                    polyline.geodesic = YES;
                    NSArray *styles = @[[GMSStrokeStyle solidColor:[UIColor whiteColor]],
                                        [GMSStrokeStyle solidColor:[UIColor blackColor]]];
                    NSArray *lengths = @[@20, @20];
                    polyline.spans = GMSStyleSpans(polyline.path, styles, lengths, kGMSLengthRhumb);
                } else {
                    polyline.strokeColor = [UIColor colorWithRed:147/255.0 green:147/255.0 blue:147/255.0 alpha:1];
                    polyline.strokeWidth = 4.f;
                    polyline.geodesic = YES;
                }
                polyline.map = self.mapView;
                
            } else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
                NSMutableArray *pathArray = [step objectForKey:@"path"];
                NSEnumerator *enmueratorpathArray = [pathArray objectEnumerator];
                NSMutableDictionary *onepath;
                
                GMSMutablePath *path = [GMSMutablePath path];
                while (onepath = [enmueratorpathArray nextObject]) {
                    [path addCoordinate:CLLocationCoordinate2DMake([[[onepath allValues] objectAtIndex:0] doubleValue], [[[onepath allValues] objectAtIndex:1] doubleValue])];
                }
                
                GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
                
                if (i==self.selected_route_number) {
                    if (colorIndex==0) {
                        selectedRouteDic = step;
                        
                        NSLog(@"selectedRouteDic%@",selectedRouteDic);
                    }
                    
                    polyline.strokeColor = [colorArray objectAtIndex:(colorIndex++)%[colorArray count]];
                    polyline.strokeWidth = 6.f;
                    polyline.geodesic = YES;
                    
                    NSMutableDictionary *departure_stop = [[step objectForKey:@"transit"] objectForKey:@"departure_stop"];
                    NSMutableDictionary *arrival_stop = [[step objectForKey:@"transit"] objectForKey:@"arrival_stop"];
                    
                    GMSMarker *departure_stop_marker = [[GMSMarker alloc] init];
                    departure_stop_marker.title = [departure_stop objectForKey:@"name"];
                    departure_stop_marker.icon = [UIImage imageNamed:@"yellowmarker_small@2x.png"];
                    departure_stop_marker.position = CLLocationCoordinate2DMake([[[[departure_stop objectForKey:@"location"] allValues] objectAtIndex:0] doubleValue], [[[[departure_stop objectForKey:@"location"] allValues] objectAtIndex:1] doubleValue]);
                    departure_stop_marker.map = self.mapView;
                    
                    GMSMarker *arrival_stop_marker = [[GMSMarker alloc] init];
                    arrival_stop_marker.title = [arrival_stop objectForKey:@"name"];
                    arrival_stop_marker.icon = [UIImage imageNamed:@"yellowmarker_small@2x.png"];
                    arrival_stop_marker.position = CLLocationCoordinate2DMake([[[[arrival_stop objectForKey:@"location"] allValues] objectAtIndex:0] doubleValue], [[[[arrival_stop objectForKey:@"location"] allValues] objectAtIndex:1] doubleValue]);
                    arrival_stop_marker.map = self.mapView;
                    
                } else {
                    polyline.strokeColor = [UIColor colorWithRed:147/255.0 green:147/255.0 blue:147/255.0 alpha:1];
                    polyline.strokeWidth = 4.f;
                    polyline.geodesic = YES;
                }
                polyline.map = self.mapView;
                
            }
        }
        if (breakFlag == 1) {
            break;
        }
    }
    
//    [self showRealtimeBus];
    
//    [realtimeUpdateTimer invalidate];
//    //    [self didUpdateRealtimeData];
//    realtimeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(showRealtimeBus) userInfo:nil repeats:YES];
}

- (void)showRealtimeBus {
    if (busMarkers==nil)
        busMarkers = [[NSMutableArray alloc] init];
    
    NSString *trip_headsign = [[selectedRouteDic objectForKey:@"transit"] objectForKey:@"headsign"];
    
    NSString *route_long_name = [[[selectedRouteDic objectForKey:@"transit"] objectForKey:@"line"] objectForKey:@"name"];
    NSString *route_short_name = [[[selectedRouteDic objectForKey:@"transit"] objectForKey:@"line"] objectForKey:@"short_name"];
    
    AppDelegate *appDelegate = ((AppDelegate*)[[UIApplication sharedApplication]delegate]);
    
    NSString *query;
    
    if (route_long_name)
        query = [NSString stringWithFormat:@"SELECT T1.route_id FROM routes AS T1 WHERE T1.route_long_name='%@'",route_long_name];
    else
        query = [NSString stringWithFormat:@"SELECT T1.route_id FROM routes AS T1 WHERE T1.route_short_name='%@'",route_short_name];
    
    NSLog(@"query:%@",query);
    
    NSArray *tripInfo;
    
    tripInfo = [[NSArray alloc] initWithArray:[appDelegate.dbManager loadDataFromDB:query]];
    
    
    if (tripInfo && [tripInfo count]>0 && (tripInfo[0])[0]) {
        //        NSLog(@"routeInfo:%@", (tripInfo[0])[0]);
        NSString *url = [NSString stringWithFormat:@"http://realtime.mbta.com/developer/api/v2/vehiclesbyroute?api_key=WrKNVUmTdEqC4fyRI7HiaQ&route=%@&format=json", (tripInfo[0])[0] ];
        
        NSLog(@"routeID:%@", (tripInfo[0])[0]);
        
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:url]];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSEnumerator *enmueratorMarker = [busMarkers objectEnumerator];
            GMSMarker *oneMarker;
            while (oneMarker = [enmueratorMarker nextObject]) {
                oneMarker.map = nil;
            }
            [busMarkers removeAllObjects];
            
            
            NSMutableArray *direction =  (NSMutableArray*)[responseObject objectForKey:@"direction"];
            
            NSEnumerator *enmueratorDirection = [direction objectEnumerator];
            NSMutableDictionary *onedirection;
            while (onedirection = [enmueratorDirection nextObject]) {
                NSMutableArray *trip =  (NSMutableArray*)[onedirection objectForKey:@"trip"];
                NSEnumerator *enmueratorTrip = [trip objectEnumerator];
                NSMutableDictionary *oneTrip;
                while (oneTrip = [enmueratorTrip nextObject]) {
                    if ([[oneTrip objectForKey:@"trip_headsign"] isEqualToString:trip_headsign]) {
                        
                        NSLog(@"oneTrip,%@",oneTrip);
                        
                        CLLocationCoordinate2D bus_position = CLLocationCoordinate2DMake([[[oneTrip objectForKey:@"vehicle"] objectForKey:@"vehicle_lat"] doubleValue], [[[oneTrip objectForKey:@"vehicle"] objectForKey:@"vehicle_lon"] doubleValue]);
                        GMSMarker *bus_marker = [GMSMarker markerWithPosition:bus_position];
                        //                        bus_marker.icon = [UIImage imageNamed:@"bus_marker2@2x.png"];
                        CGRect cgrect = CGRectMake(0, 0, 36,52);
                        BusAnnotationView *busAnnotation = [[BusAnnotationView alloc] initWithFrame:cgrect];
                        
                        NSString *routeName = route_long_name?route_long_name:route_short_name;
                        
                        bus_marker.icon = [busAnnotation snapshot:busAnnotation routeName:routeName busDistance:1];
                        [busMarkers addObject:bus_marker];
                        
                        //                        NSString *url = [NSString stringWithFormat:@"http://realtime.mbta.com/developer/api/v2/schedulebytrip?api_key=WrKNVUmTdEqC4fyRI7HiaQ&trip=%@&format=json", tripID ];
                        //
                        //                        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:url]];
                        //                        manager.securityPolicy.allowInvalidCertificates = YES;
                        //                        manager.requestSerializer = [AFJSONRequestSerializer serializer];
                        //                        [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        //
                        //                            NSMutableArray *stops =  (NSMutableArray*)[responseObject objectForKey:@"stop"];
                        //
                        //                            NSEnumerator *enmueratorStops = [stops objectEnumerator];
                        //                            NSMutableDictionary *oneStop;
                        //                            while (oneStop = [enmueratorStops nextObject]) {
                        //                                if ([[oneStop objectForKey:@"stop_name"] isEqualToString:departure_stop_name]) {
                        //
                        ////                                    NSLog(@"departure_stop_name%@, departure_time_value%@",departure_stop_name,departure_time_value);
                        //
                        //
                        //
                        //                                    NSString * timeStampString =[oneStop objectForKey:@"sch_dep_dt"];
                        //                                    NSTimeInterval _interval=[timeStampString doubleValue];
                        //                                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
                        //                                    NSDateFormatter *_formatter=[[NSDateFormatter alloc]init];
                        //                                    [_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                        //                                    [_formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                        //                                    NSString *_date=[_formatter stringFromDate:date];
                        //
                        //                                    NSLog(@"departure_time_value%@,_date%@", departure_time_value, _date);
                        //
                        //                                }
                        //                            }
                        //
                        //                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        //                            NSLog(@"Error: %@", error);
                        //                        }];
                    }
                    
                }
            }
            
            enmueratorMarker = [busMarkers objectEnumerator];
            while (oneMarker = [enmueratorMarker nextObject]) {
                oneMarker.map = self.mapView;
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }
    
}

//- (BOOL)checkIfTrip:(NSString *)tripID departure_time_value:(NSString *) departure_time_value departure_stop_name:(NSString *) departure_stop_name {
//    NSString *url = [NSString stringWithFormat:@"http://realtime.mbta.com/developer/api/v2/schedulebytrip?api_key=WrKNVUmTdEqC4fyRI7HiaQ&trip=%@&format=json", tripID ];
//
//    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:url]];
//    manager.securityPolicy.allowInvalidCertificates = YES;
//    manager.requestSerializer = [AFJSONRequestSerializer serializer];
//    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//
//        NSMutableArray *stops =  (NSMutableArray*)[responseObject objectForKey:@"stop"];
//
//        NSEnumerator *enmueratorStops = [stops objectEnumerator];
//        NSMutableDictionary *oneStop;
//        while (oneStop = [enmueratorStops nextObject]) {
//            if ([[oneStop objectForKey:@"stop_name"] isEqualToString:departure_stop_name]) {
//
//                NSLog(@"departure_stop_name%@, departure_time_value%@",departure_stop_name,departure_time_value);
//
//            }
//        }
//
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
//    }];
//}

- (void)initScroll {
    
    routeScrollArray = [[NSMutableArray alloc] init];
    
    CGFloat cellHeight = self.uiscrollview_routes.frame.size.height;
    CGFloat cellWidth = cellHeight*2.25;
    
    CGFloat scrollViewContentWidth = 0;
    
    UIColor *borderColor = [UIColor lightGrayColor];
    
    
    for (int i=0; i<[[self.route_dic objectForKey:@"routes"] count]; i++) {
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(scrollViewContentWidth, 0, cellWidth, cellHeight)];
        view.tag = i;
        [routeScrollArray addObject:view];
        view.layer.borderColor = borderColor.CGColor;
        view.layer.borderWidth = 0.5f;
        
        
        if (i==self.selected_route_number) {
            view.layer.borderColor = DefaultYellow.CGColor;
            view.layer.borderWidth = 3.0f;
        }
        
        //        UIView *viewTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, cellHeight-20)];
        //        viewTitle.backgroundColor = [UIColor blackColor];
        //
        //        [view addSubview:viewTitle];
        CGRect titleLabelRectangle = CGRectMake(0, 0, cellWidth, 22);
        UILabel *titleLabel = [[UILabel alloc]initWithFrame:titleLabelRectangle];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor darkGrayColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        //        titleLabel.text = [NSString stringWithFormat:@"Route %d",i+1];
        titleLabel.text = @"Walk";
        titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:13];
        titleLabel.numberOfLines=1;
        //        [titleLabel sizeToFit];
        [view addSubview:titleLabel];
        
        
        CGRect detailLabelRectangle = CGRectMake(7, 22, cellWidth-2*5, 45);
        UILabel *detailLabel = [[UILabel alloc]initWithFrame:detailLabelRectangle];
        detailLabel.textColor = [UIColor blackColor];
        detailLabel.textAlignment = NSTextAlignmentCenter;
        detailLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:13];
        detailLabel.numberOfLines=0;
        //        [detailLabel sizeToFit];
        [view addSubview:detailLabel];
        
        //button for touch
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:@"" forState:UIControlStateNormal];
        btn.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
        [btn setBackgroundColor:[UIColor clearColor]];
        
        [btn addTarget:self
                action:@selector(didSelectRoute:)
      forControlEvents:UIControlEventTouchDown];
        
        [view addSubview:btn];
        
        [self.uiscrollview_routes addSubview:view];
        
        
        NSMutableDictionary *leg_array = [[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"legs"] objectAtIndex:0];
        
        if ([leg_array objectForKey:@"departure_time"] && [leg_array objectForKey:@"arrival_time"])
            titleLabel.text = [NSString stringWithFormat:@"%@ - %@", [[leg_array objectForKey:@"departure_time"] objectForKey:@"text"], [@"" stringByAppendingString:[[leg_array objectForKey:@"arrival_time"] objectForKey:@"text"]] ];
        NSString *route_details = @"";
        
        NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
        NSEnumerator *enmueratorsteps_array = [steps_array objectEnumerator];
        NSMutableDictionary *step;
        while (step = [enmueratorsteps_array nextObject]) {
            if (![route_details isEqualToString:@""]) {
                route_details = [route_details stringByAppendingString:@" >"];
            }
            
            if ([[step objectForKey:@"travel_mode"] isEqualToString:@"WALKING"]) {
                route_details = [route_details stringByAppendingString:@" \U0001F6B6"];
                
            } else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
                route_details = [route_details stringByAppendingString:@" \U0001F68C"];
                NSString *short_name = [[[step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"short_name"];
                NSString *name = [[[step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"name"];
                
                if (short_name)
                    route_details = [route_details stringByAppendingString:[NSString stringWithFormat:@" %@", short_name]];
                else if (name)
                    route_details = [route_details stringByAppendingString:[NSString stringWithFormat:@" %@", name]];
            }
        }
        
        detailLabel.text = route_details;
        
        scrollViewContentWidth += cellWidth;
    }
    
    
    self.uiscrollview_routes.contentSize = CGSizeMake(scrollViewContentWidth, self.uiscrollview_routes.frame.size.height );
    
    UIView *view = [routeScrollArray objectAtIndex:self.selected_route_number];
    [self.uiscrollview_routes scrollRectToVisible:view.frame animated:YES];
    
}

//- (void)updateSelectedRouteOnScroll:(long) i {
//    //
//    UIView *oldSelectedView = [routeScrollArray objectAtIndex:self.selected_route_number];
//    for (UIView *i in oldSelectedView.subviews){
//        if([i isKindOfClass:[UILabel class]]){
//            UILabel *dayLabel = (UILabel *)i;
//            if(dayLabel.tag >0){
//                dayLabel.backgroundColor = [UIColor clearColor];
//            }
//        }
//    }
//
//    self.selected_route_number = i;
//
//    //
//    UIView *newSelectedView = [routeScrollArray objectAtIndex:self.selected_route_number];
//    for (UIView *i in newSelectedView.subviews){
//        if([i isKindOfClass:[UILabel class]]){
//            UILabel *dayLabel = (UILabel *)i;
//            if(dayLabel.tag >0){
//                dayLabel.backgroundColor = DefaultYellow;
//            }
//        }
//    }
//}

- (void)didSelectRoute:(id)sender {
    UIButton *btn = (UIButton *)sender;
    UIView *view = btn.superview;
    
    //    [self updateSelectedRouteOnScroll:view.tag];
    
    if (view.tag==self.selected_route_number)
        return;
    else
        self.selected_route_number = view.tag;
    
    for (int i=0; i<[routeScrollArray count]; i++) {
        UIView *view2 = [routeScrollArray objectAtIndex:i];
        view2.layer.borderColor = [UIColor lightGrayColor].CGColor;
        view2.layer.borderWidth = 0.5f;
    }
    
    view.layer.borderColor = DefaultYellow.CGColor;
    view.layer.borderWidth = 3.0f;
    
    [self showSelectedRoute];
}

- (void)startAnimation {
    self.CSAnimationView_top.type = CSAnimationTypeSlideDown;
    self.CSAnimationView_top.duration = 0.3;
    self.CSAnimationView_top.delay = 0.30;
    [self.CSAnimationView_top startCanvasAnimation];
    
    self.CSAnimationView_scroll.type = CSAnimationTypeFadeIn;
    self.CSAnimationView_scroll.duration = 0.3;
    self.CSAnimationView_scroll.delay = 0.37;
    [self.CSAnimationView_scroll startCanvasAnimation];
    
    self.CSAnimationView_map.type = CSAnimationTypeFadeIn;
    self.CSAnimationView_map.duration = 0.3;
    self.CSAnimationView_map.delay = 0.44;
    [self.CSAnimationView_map startCanvasAnimation];
    
    self.CSAnimationView_top.alpha=1;
    self.CSAnimationView_scroll.alpha=1;
    self.CSAnimationView_map.alpha=1;
}

- (void)startAnimationToFadeEverything {
    self.CSAnimationView_top.alpha=0;
    
    self.CSAnimationView_map.alpha=0;
    
    self.CSAnimationView_top.alpha=0;
}

- (IBAction)btn_back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)btn_addToAgenda:(id)sender {
    
    if ([statusView isDescendantOfView:self.view])
        return;
    statusView = [[StatusView alloc] initWithText:@"Saving to agenda" delayToHide:0.7 iconIndex:0];
    [self.view addSubview:statusView];
    
    [self saveAgenda_allInOne];
}

- (void)saveAgenda_allInOne {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        savedAgenda = [NSMutableDictionary dictionaryWithCapacity:10];
        
        //
        NSArray *sysPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory ,NSUserDomainMask, YES);
        NSString *documentsDirectory = [sysPaths objectAtIndex:0];
        NSString *fileName = @"agenda.tmp";
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent: fileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSData *archiverData = [NSData dataWithContentsOfFile:filePath];
            savedAgenda = [NSKeyedUnarchiver unarchiveObjectWithData:archiverData];
            if (!savedAgenda)
                savedAgenda = [NSMutableDictionary dictionaryWithCapacity:10];
        }
        
        ///
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        NSDate *date = [NSDate date];
        NSString *formattedDateString = [dateFormatter stringFromDate:date];
        NSMutableDictionary *agendaForDate = [savedAgenda objectForKey:formattedDateString];
        
        if (!agendaForDate) {
            agendaForDate = [NSMutableDictionary dictionaryWithCapacity:3];
        }
        
        if (true) {
            NSString *keyString = @"";
            
            NSMutableDictionary *leg_array = [[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:self.selected_route_number] objectForKey:@"legs"] objectAtIndex:0];
            
            if ([leg_array objectForKey:@"departure_time"] && [leg_array objectForKey:@"arrival_time"])
                keyString = [keyString stringByAppendingString:[NSString stringWithFormat:@"%@ - %@", [[leg_array objectForKey:@"departure_time"] objectForKey:@"text"], [@"" stringByAppendingString:[[leg_array objectForKey:@"arrival_time"] objectForKey:@"text"]] ] ];
            NSString *route_details = @"";
            
            NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
            NSEnumerator *enmueratorsteps_array = [steps_array objectEnumerator];
            NSMutableDictionary *step;
            while (step = [enmueratorsteps_array nextObject]) {
                if (![route_details isEqualToString:@""]) {
                    route_details = [route_details stringByAppendingString:@" >"];
                }
                
                if ([[step objectForKey:@"travel_mode"] isEqualToString:@"WALKING"]) {
                    route_details = [route_details stringByAppendingString:@" \U0001F6B6"];
                    
                } else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
                    route_details = [route_details stringByAppendingString:@" \U0001F68C"];
                    NSString *short_name = [[[step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"short_name"];
                    NSString *name = [[[step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"name"];
                    
                    if (short_name)
                        route_details = [route_details stringByAppendingString:[NSString stringWithFormat:@" %@", short_name]];
                    else if (name)
                        route_details = [route_details stringByAppendingString:[NSString stringWithFormat:@" %@", name]];
                }
            }
            
            keyString = [keyString stringByAppendingString: route_details];
            
            [agendaForDate setObject:[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:self.selected_route_number] forKey:keyString];
        }
        
        [savedAgenda setObject:agendaForDate forKey:formattedDateString];
        
        NSData *archiverData = [NSKeyedArchiver archivedDataWithRootObject:savedAgenda];
        
        
        //        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        //        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        //        success = success;
        
        //        BOOL didWriteToFile = [archiverData writeToFile:filePath atomically:YES];
        
        BOOL success = [archiverData writeToFile:filePath options:NSDataWritingAtomic error:&error];
        //        NSLog(@"savedAgenda: %@", savedAgenda);
        NSLog(@"Success = %d, error = %@", success, error);
    });
}
@end
