//
//  PlannerViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 4/26/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "PlannerViewController.h"
#import "RouteTableViewCell.h"
#import "ColorConstants.h"
#import "RouteTableViewCell.h"
#import "StatusView.h"
#import "MapViewController.h"
#import "AppDelegate.h"

#import "JSONParser.h"

enum ViewStatus {
    ViewStatus_mapview,
    ViewStatus_datepickerview,
    ViewStatus_routeview,
    ViewStatus_recurring
};

@interface PlannerViewController () {
    int isFirstTime;
    
    UIWebView *webView;
    
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    
    enum ViewStatus viewStatus;
    
    NSMutableDictionary *route_dic;
    
    StatusView *statusView;
    
    AppDelegate *appDelegate;
    
    // Local preferred route
    NSMutableArray *localCalendarArray;
    
    // Text on Leave now button
    NSString *leaveNowTimeText;
    
    JSONParser *jsonParser;
}

@property (strong, nonatomic) GMSMapView *mapView;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (strong, nonatomic) GMSMarker *marker;
@property (strong, nonatomic) GMSMarker *frommarker;
@property (strong, nonatomic) GMSMarker *tomarker;
@property (strong, nonatomic) GMSMarker *currentlyTappedMarker;
@property (strong, nonatomic) UIView *displayedInfoWindow;

@end

@implementation PlannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self startAnimationToFadeEverything];
    isFirstTime = 1;
    viewStatus = ViewStatus_mapview;
    [self UpdateViewByViewStatus];
    
    [super viewDidLoad];
    
    [self initWebview];
    
    self.uitextfield_from.text = @"1025 16th Ave S #102 Nashville, TN 37212";
    self.uitextfield_to.text = @"2126 Abbott Martin Rd Nashville, TN 37215";
    
    self.uitextfield_from.delegate = self;
    self.uitextfield_to.delegate = self;
    
    // AppDelegate
    appDelegate = ((AppDelegate*)[[UIApplication sharedApplication]delegate]);
    
    jsonParser = [[JSONParser alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self getCurrentLocation];
    
    if (isFirstTime==1) {
        [self initMap];
//        [self updateFromToMarkersLocations];
        [self initWeekdayButtonsForRecurring];
        isFirstTime = 0;
    }
    
    [self startAnimation];
    
    [self checkIfReschedule];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self startAnimationToFadeEverything];
}

-(void)getCurrentLocation {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager startUpdatingLocation];
}

-(void)checkIfReschedule {
    if (appDelegate.reschedule_route_dictionary !=nil) {
        
        
        self.uitextfield_from.text = [appDelegate.reschedule_route_dictionary objectForKey:@"lbl_from"];
        self.uitextfield_to.text = [appDelegate.reschedule_route_dictionary objectForKey:@"lbl_to"];
        [self.uidatepicker setDate: [NSDate dateWithTimeIntervalSince1970: [[appDelegate.reschedule_route_dictionary objectForKey:@"when_time"] integerValue]]];
        self.segment_whentoleave.selectedSegmentIndex=[[appDelegate.reschedule_route_dictionary objectForKey:@"when_status"] integerValue];
        
        appDelegate.reschedule_route_dictionary = nil;
        [self.uibutton_search setTitle:@"Cancel" forState:UIControlStateNormal];
        [self updateFromToMarkersLocations];
        [self btn_search:nil];
        
        
//        NSLog(@"checkIfReschedule!!!!");
    } else {
//        NSLog(@"checkIfReschedule----");
    }
}

- (void)initWeekdayButtonsForRecurring {
    NSArray *subviews = [self.CSAnimationView_Recurring subviews];
    
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            if (subview.tag)
                if (subview.tag>0) {
                    UIButton *button = (UIButton *)subview;
                    [button setBackgroundColor: WeekdayButtonUnclicked];
                    [button addTarget:self action:@selector(didClickWeekdayButton:) forControlEvents:UIControlEventTouchUpInside];
                }
        }
        
    }
}

- (void)didClickWeekdayButton:(UIButton *) sender {
    if (sender.tag<10) {
        [sender setBackgroundColor: WeekdayButtonClicked];
        sender.tag = sender.tag+10;
    } else {
        [sender setBackgroundColor: WeekdayButtonUnclicked];
        sender.tag = sender.tag-10;
    }
}

- (void)initWebview {
    webView = [[UIWebView alloc] init];
    webView.delegate = self;
    //    [webView loadHTMLString:@"<script src=\"calc.js\"></script>" baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GoogleMap" ofType:@"html"]isDirectory:NO]]];
}

- (void)initMap {
    geocoder = [[CLGeocoder alloc] init];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:42.359879 longitude:-71.058616 zoom:14];
    self.mapView = [GMSMapView mapWithFrame:self.CSAnimationView_Map.bounds camera:camera];
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    [self.CSAnimationView_Map addSubview:self.mapView];
    
    UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [myButton addTarget:self action:@selector(myLocation:) forControlEvents:UIControlEventTouchUpInside];
    [myButton setBackgroundImage:[UIImage imageNamed:@"location_icon@2x.png"] forState:UIControlStateNormal];
    myButton.frame = CGRectMake(self.CSAnimationView_Map.frame.size.width-47.0, self.CSAnimationView_Map.frame.size.height-47.0, 32.0, 32.0);
    
    GMSMarker *marker2 = [[GMSMarker alloc] init];
    
    marker2.title = @"";
    marker2.icon = [UIImage imageNamed:@"mylocation_marker@2x.png"];
    marker2.position = CLLocationCoordinate2DMake(42.359879, -71.058616);
    marker2.map = self.mapView;
    
    [self.CSAnimationView_Map addSubview:myButton];
    
}

- (void)myLocation:(UIButton *)sender {
    [self.mapView animateToLocation:self.locationManager.location.coordinate];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //    return [route_array count];
    return [[route_dic objectForKey:@"routes"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RouteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RouteCell"];
    
    //    cell.lbl_route_details.text = @"\U0001F6B6 > \U0001F68C SL5 > \U0001F6B6";
    
    NSMutableDictionary *route_dic_local = [((NSMutableArray *)[route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row];
    
    NSMutableDictionary *result = [jsonParser getRouteDetails:route_dic_local];
    
    cell.lbl_start_time.text = [result objectForKey:@"start_time"];
    
    cell.lbl_end_time.text = [result objectForKey:@"end_time"];
    
    cell.lbl_month.text = [result objectForKey:@"date"];
    
    cell.lbl_route_details.text = [result objectForKey:@"route_details"];
    
    cell.lbl_route_times.text = [result objectForKey:@"route_times"];
    
    /*
    NSMutableDictionary *leg_array = [[[((NSMutableArray *)[route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row] objectForKey:@"legs"] objectAtIndex:0];
    
    // Change time to local time
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    
    NSDate * Preferred_departure_time = [formatter dateFromString:[[leg_array objectForKey:@"departure_time"] objectForKey:@"value"]];
    NSDate * Preferred_arrival_time = [formatter dateFromString:[[leg_array objectForKey:@"arrival_time"] objectForKey:@"value"]];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"hh:mma"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setLocale:locale];
    
    cell.lbl_start_time.text = [df stringFromDate: Preferred_departure_time];
    
    cell.lbl_end_time.text = [NSString stringWithFormat:@"-%@", [df stringFromDate: Preferred_arrival_time]];
    
    [df setDateFormat:@"MMM dd"];
    
    cell.lbl_month.text = [df stringFromDate: Preferred_departure_time];
    
    //    "travel_mode" = WALKING;
    
    float walking_time = 0.0;
    
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
            
            walking_time = walking_time + [[[step objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60;
            
        } else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
            route_details = [route_details stringByAppendingString:@" \U0001F68C"];
            NSString *short_name = [[[step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"short_name"];
            NSString *name = [[[step objectForKey:@"transit"] objectForKey: @"line"] objectForKey: @"name"];
            
            if (short_name)
                route_details = [route_details stringByAppendingString:short_name];
            else if (name)
                route_details = [route_details stringByAppendingString:name];
        }
    }
    
    cell.lbl_route_details.text = route_details;
    
    cell.lbl_route_times.text = [NSString stringWithFormat:@"Total: %.1fmin Walk: %.1fmin", [[[leg_array objectForKey:@"duration"] objectForKey:@"value"] floatValue]/60, walking_time ];
    
    NSInteger total_seconds = [[[leg_array objectForKey:@"duration"] objectForKey:@"value"] integerValue];
    NSInteger walking_seconds = walking_time*60;
    
    Calendar *localCalendar = [[Calendar alloc] initWithValues:self.uitextfield_from.text Address_to:self.uitextfield_to.text When_status:self.segment_whentoleave.selectedSegmentIndex When_time:[self.uidatepicker.date timeIntervalSince1970] Scheduled_departure_time:[Preferred_departure_time timeIntervalSince1970] Scheduled_arrival_time:[Preferred_arrival_time timeIntervalSince1970] Scheduled_walking_time:walking_seconds Scheduled_total_time:total_seconds Scheduled_details:cell.lbl_route_details.text Scheduled_dictionary:leg_array Whole_dictionary:[[((NSMutableArray *)[route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row] objectForKey:@"bounds"]];
    
    
    if ([[localCalendarArray objectAtIndex:indexPath.row] isEqual:[NSNull null]]) {
        [localCalendarArray insertObject:localCalendar atIndex:indexPath.row];
    }
    
    */
    
    [cell.uibtn_prefer addTarget:self action:@selector(addToCalendar:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.uitableview_routes deselectRowAtIndexPath:indexPath animated:YES];
    
    MapViewController * mapViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mapViewController"];
    mapViewController.route_dic = route_dic;
    mapViewController.selected_route_number = indexPath.row;
    [self presentViewController:mapViewController animated:NO completion:nil];
    return;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

-(void)deletePreviousRecord {
    NSString *query = [NSString stringWithFormat:@"DELETE FROM thub_plans WHERE when_time=%.0f AND when_status=%ld",[self.uidatepicker.date timeIntervalSince1970], (long)self.segment_whentoleave.selectedSegmentIndex];
    
    [appDelegate.dbManager executeQuery:query];
    
    query = [NSString stringWithFormat:@"DELETE FROM thub_scheduled_trips WHERE when_time=%.0f AND when_status=%ld",[self.uidatepicker.date timeIntervalSince1970], (long)self.segment_whentoleave.selectedSegmentIndex];
    
    [appDelegate.dbManager executeQuery:query];
}

- (void)addToCalendar:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.uitableview_routes];
    NSIndexPath *indexPath = [self.uitableview_routes indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil)
    {
        
        NSMutableDictionary *route_dic_local = [((NSMutableArray *)[route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row];
        
        NSMutableDictionary *result = [jsonParser getRouteDetails:route_dic_local];
        
//        NSLog(@"rrrrrrrr:%@", result);
        
        
        [self deletePreviousRecord];
        
        NSString *query = [NSString stringWithFormat:@"INSERT INTO thub_plans (address_from, address_to, when_status, when_time) VALUES ('%@', '%@', %ld, %.0f)", self.uitextfield_from.text, self.uitextfield_to.text, (long)self.segment_whentoleave.selectedSegmentIndex,[self.uidatepicker.date timeIntervalSince1970]];
        
        [appDelegate.dbManager executeQuery:query];
        
        NSString *route_dictionary = [[NSString stringWithFormat:@"%@", [((NSMutableArray *)[route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row] ]  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        query = [NSString stringWithFormat:@"INSERT INTO thub_scheduled_trips (when_status, when_time, route_dictionary, departure_timestamp, arrival_timestamp) VALUES (%ld, %.0f, '%@', %.0f, %.0f)", (long)self.segment_whentoleave.selectedSegmentIndex, [self.uidatepicker.date timeIntervalSince1970], route_dictionary, [[result objectForKey:@"departure_timestamp"] floatValue], [[result objectForKey:@"arrival_timestamp"] floatValue]];
        
        [appDelegate.dbManager executeQuery:query];
        
        viewStatus = ViewStatus_recurring;
        [self UpdateViewByViewStatus];
    }
}


- (bool)checkIfTimeOverlapping:(Calendar *) localCalendar {
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM T_Calendar WHERE Scheduled_departure_time<'%ld' AND Scheduled_arrival_time>'%ld' OR Scheduled_departure_time<'%ld' AND Scheduled_arrival_time>'%ld' OR Scheduled_departure_time='%ld' AND Scheduled_arrival_time='%ld'",(long)localCalendar.Scheduled_departure_time, localCalendar.Scheduled_departure_time, localCalendar.Scheduled_arrival_time, localCalendar.Scheduled_arrival_time, localCalendar.Scheduled_departure_time, localCalendar.Scheduled_arrival_time];
    NSArray *responseInfo;
    responseInfo = [[NSArray alloc] initWithArray:[appDelegate.dbManager loadDataFromDB:query]];
    if ([responseInfo count]>0)
        return YES;
    else
        return NO;
    
}

- (void)didSetAsPreferred:(id)sender {
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.uitableview_routes];
    NSIndexPath *indexPath = [self.uitableview_routes indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil)
    {
        
        Calendar *localCalendar = [localCalendarArray objectAtIndex:indexPath.row];
        
        if ([self checkIfTimeOverlapping:localCalendar]) {
            statusView = [[StatusView alloc] initWithText:@"Time period is overlapping another time period in the Calendar, please delete the existing overlapping one before adding a new schedule." delayToHide:2.0 iconIndex:0];
            [self.view addSubview:statusView];
            return;
        }
        
        if ([statusView isDescendantOfView:self.view])
            return;
        statusView = [[StatusView alloc] initWithText:@"Added to Calendar" delayToHide:0.7 iconIndex:0];
        [self.view addSubview:statusView];
        //    @property (nonatomic, strong) NSString *Address_from;
        //    @property (nonatomic, strong) NSString *Address_to;
        //    @property (nonatomic, assign) NSInteger When_status;
        //    @property (nonatomic, assign) NSInteger When_time;
        //    @property (nonatomic, assign) NSInteger Scheduled_departure_time;
        //    @property (nonatomic, assign) NSInteger Scheduled_arrival_time;
        //    @property (nonatomic, assign) NSInteger Scheduled_walking_time;
        //    @property (nonatomic, assign) NSInteger Scheduled_total_time;
        //    @property (nonatomic, assign) NSString *Scheduled_details;
        //    @property (nonatomic, assign) NSString *Scheduled_dictionary;
        
        NSString *string_dic = [[NSString stringWithFormat:@"%@", localCalendar.Scheduled_dictionary ]  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *whole_dic = [[NSString stringWithFormat:@"%@", localCalendar.Whole_dictionary ]  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        [encodedText stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSString *query = [NSString stringWithFormat:@"INSERT INTO T_Calendar (Address_from, Address_to, When_status, When_time, Scheduled_departure_time, Scheduled_arrival_time, Scheduled_walking_time, Scheduled_total_time, Scheduled_details, Scheduled_dictionary, Whole_dictionary) VALUES ('%@', '%@', '%ld', '%ld', '%ld', '%ld', '%ld', '%ld', '%@', '%@', '%@')", localCalendar.Address_from, localCalendar.Address_to, (long)localCalendar.When_status, localCalendar.When_time, localCalendar.Scheduled_departure_time, localCalendar.Scheduled_arrival_time, localCalendar.Scheduled_walking_time, localCalendar.Scheduled_total_time, localCalendar.Scheduled_details, string_dic, whole_dic];
        
        
        [appDelegate.dbManager executeQuery:query];
        
        [self.uitableview_routes reloadData];
        
        viewStatus = ViewStatus_recurring;
//        [self.uibutton_search setTitle:@"Plan" forState:UIControlStateNormal];
        [self UpdateViewByViewStatus];
    }
}

- (void)UpdateViewByViewStatus {
    switch (viewStatus) {
        case ViewStatus_mapview:
            self.CSAnimationView_timePicker.hidden = YES;
            self.CSAnimationView_routes.hidden = YES;
            self.mapView.userInteractionEnabled = YES;
            self.CSAnimationView_Recurring.hidden = YES;
            break;
        case ViewStatus_datepickerview: {
            self.CSAnimationView_timePicker.hidden = NO;
            self.CSAnimationView_routes.hidden = YES;
            self.mapView.userInteractionEnabled = NO;
            self.CSAnimationView_Recurring.hidden = YES;
            
            [self.CSAnimationView_Map bringSubviewToFront:self.CSAnimationView_timePicker];
            self.CSAnimationView_timePicker.type = CSAnimationTypeBounceUp;
            self.CSAnimationView_timePicker.duration = 0.3;
            self.CSAnimationView_timePicker.delay = 0.0;
            [self.CSAnimationView_timePicker startCanvasAnimation];
            
            NSDate *currentDate = [NSDate date];
            [self.uidatepicker setMinimumDate:currentDate];
            
            // Segment
            UIFont *segment_font = [UIFont fontWithName:@"AvenirNext-Regular" size:13];
            NSDictionary *attributes = [NSDictionary dictionaryWithObject:segment_font
                                                                   forKey:NSFontAttributeName];
            [self.segment_whentoleave setTitleTextAttributes:attributes
                                            forState:UIControlStateNormal];
            [self.segment_whentoleave addTarget:self action:@selector(didSegmentValueChange:) forControlEvents:UIControlEventValueChanged];
//            self.uidatepicker.enabled = NO;
            self.uidatepicker.hidden = YES;
            
            break;
        }
        case ViewStatus_routeview: {
            self.CSAnimationView_timePicker.hidden = YES;
            self.CSAnimationView_routes.hidden = NO;
            self.CSAnimationView_Recurring.hidden = YES;
            [self.CSAnimationView_Map bringSubviewToFront:self.CSAnimationView_routes];
            self.CSAnimationView_routes.type = CSAnimationTypeBounceUp;
            self.CSAnimationView_routes.duration = 0.3;
            self.CSAnimationView_routes.delay = 0.0;
            [self.CSAnimationView_routes startCanvasAnimation];
            
            self.mapView.userInteractionEnabled = NO;
            break;
        }
        case ViewStatus_recurring: {
            self.CSAnimationView_timePicker.hidden = YES;
            self.CSAnimationView_routes.hidden = YES;
            self.CSAnimationView_Recurring.hidden = NO;
            [self.CSAnimationView_Map bringSubviewToFront:self.CSAnimationView_Recurring];
            self.CSAnimationView_Recurring.type = CSAnimationTypeBounceUp;
            self.CSAnimationView_Recurring.duration = 0.3;
            self.CSAnimationView_Recurring.delay = 0.0;
            [self.CSAnimationView_Recurring startCanvasAnimation];
            
            self.mapView.userInteractionEnabled = NO;
            break;
        }
        default:
            break;
    }
}

- (void)didSegmentValueChange:(UISegmentedControl *) sender {
    NSString * theTitle = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
    
    if ([theTitle rangeOfString:@"Leave Now"].location != NSNotFound ) {
//        NSDate *currentDate = [NSDate date];
//        [self.uidatepicker setDate:currentDate];
        self.uidatepicker.hidden = YES;
    } else
        self.uidatepicker.hidden = NO;
}

//- (void)datePickerValueChanged:(id) sender {
//    //    NSLog(@"%@", @"datePickerValueChanged");
//    
//    UIDatePicker * datePicker = (UIDatePicker *)sender;
//    
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    [df setDateFormat:@"MM/dd/yyyy hh:mm a"];
//    //    df.dateStyle = NSDateFormatterMediumStyle;
//    ////    df.dateStyle = NSDateFormatterLongStyle;
//    //    df.timeStyle = NSDateFormatterShortStyle;
//    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
//    [df setLocale:locale];
//    
//    
//}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker
{
    UIView *view = [[UIView alloc] init];
    view.frame = CGRectMake(0, 0, 0, 0);
    
    return view;
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    return YES;
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position
{
    [self updateDisplayInfoWindowPosition];
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
//    if (searchStatus==1)
//        return;
    
    self.marker.map = nil;
    
    self.marker = [[GMSMarker alloc] init];
    
    self.marker.title = @"";
    self.marker.icon = [UIImage imageNamed:@"yellowmarker@2x.png"];
    self.marker.position = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude);
    self.marker.map = self.mapView;
    
    [self.mapView setSelectedMarker:nil];
    
    if([self.displayedInfoWindow isDescendantOfView:self.view]) {
        [self.displayedInfoWindow removeFromSuperview];
        self.displayedInfoWindow = nil;
    }
    
    self.displayedInfoWindow = [[UIView alloc] init];
    self.displayedInfoWindow.backgroundColor = [UIColor whiteColor];
    
    [self updateDisplayInfoWindowPosition];
    
    CGRect cgrect_btn_from = CGRectMake(10, 5, 80, 30);
    UIButton *btn_from = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn_from setTitle:@"Start here" forState:UIControlStateNormal];
    btn_from.frame = cgrect_btn_from;
    [btn_from setBackgroundColor:[UIColor clearColor]];
    [btn_from setTitleColor:DefaultGreen forState:UIControlStateNormal];
    btn_from.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16];
    
    [btn_from addTarget:self
                 action:@selector(didPressMarkerFrom:)
       forControlEvents:UIControlEventTouchDown];
    [self.displayedInfoWindow addSubview:btn_from];
    
    CGRect cgrect_btn_to = CGRectMake(100, 5, 70, 30);
    UIButton *btn_to = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn_to setTitle:@"End here" forState:UIControlStateNormal];
    btn_to.frame = cgrect_btn_to;
    [btn_to setBackgroundColor:[UIColor clearColor]];
    [btn_to setTitleColor:DefaultRed forState:UIControlStateNormal];
    btn_to.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16];
    
    [btn_to addTarget:self
               action:@selector(didPressMarkerTo:)
     forControlEvents:UIControlEventTouchDown];
    [self.displayedInfoWindow addSubview:btn_to];
    
    [self.CSAnimationView_Map addSubview:self.displayedInfoWindow];
    
    [self.view bringSubviewToFront:self.CSAnimationView_Top];
    [self.view bringSubviewToFront:self.CSAnimationView_FromGo];
}

- (void)updateDisplayInfoWindowPosition
{
    CGPoint markerPoint = [self.mapView.projection pointForCoordinate:self.marker.position];
    self.displayedInfoWindow.frame = CGRectMake(markerPoint.x-95 , markerPoint.y - 30-40, 170, 40);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"didUpdateLocations");
    CLLocation *location = [locations lastObject];
    [self.mapView animateToLocation:location.coordinate];
    [self.locationManager stopUpdatingLocation];
}

- (void)didPressMarkerFrom:(id)sender
{
    CLLocation *sectorLocation = [[CLLocation alloc] initWithLatitude:self.marker.position.latitude longitude:self.marker.position.longitude];
    
    
    [geocoder reverseGeocodeLocation:sectorLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        //        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            self.uitextfield_from.text = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                          placemark.subThoroughfare, placemark.thoroughfare,
                                          placemark.postalCode, placemark.locality,
                                          placemark.administrativeArea,
                                          placemark.country];
            self.marker.map=nil;
            
            [self.displayedInfoWindow removeFromSuperview];
            self.displayedInfoWindow = nil;
            
            if (!self.frommarker) {
                self.frommarker =  [[GMSMarker alloc] init];
                self.frommarker.map = self.mapView;
            }
            self.frommarker.icon = [UIImage imageNamed:@"greenmarker@2x.png"];
            self.frommarker.position = CLLocationCoordinate2DMake(self.marker.position.latitude, self.marker.position.longitude);
            
            [self updateFromToMarkersLocations];
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
    
    
    
}

- (void)didPressMarkerTo:(id)sender
{
    CLLocation *sectorLocation = [[CLLocation alloc] initWithLatitude:self.marker.position.latitude longitude:self.marker.position.longitude];
    
    [geocoder reverseGeocodeLocation:sectorLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        //        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            self.uitextfield_to.text = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                        placemark.subThoroughfare, placemark.thoroughfare,
                                        placemark.postalCode, placemark.locality,
                                        placemark.administrativeArea,
                                        placemark.country];
            
            self.marker.map=nil;
            
            [self.displayedInfoWindow removeFromSuperview];
            self.displayedInfoWindow = nil;
            
            if (!self.tomarker) {
                self.tomarker =  [[GMSMarker alloc] init];
                self.tomarker.map = self.mapView;
            }
            self.tomarker.icon = [UIImage imageNamed:@"redmarker@2x.png"];
            self.tomarker.position = CLLocationCoordinate2DMake(self.marker.position.latitude, self.marker.position.longitude);
            
            [self updateFromToMarkersLocations];
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
    
}

- (CLLocationCoordinate2D) geoCodeUsingAddress:(NSString *)address
{
    double latitude = 0, longitude = 0;
    NSString *esc_addr =  [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *req = [NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?sensor=false&address=%@", esc_addr];
    NSString *result = [NSString stringWithContentsOfURL:[NSURL URLWithString:req] encoding:NSUTF8StringEncoding error:NULL];
    if (result) {
        NSScanner *scanner = [NSScanner scannerWithString:result];
        if ([scanner scanUpToString:@"\"lat\" :" intoString:nil] && [scanner scanString:@"\"lat\" :" intoString:nil]) {
            [scanner scanDouble:&latitude];
            if ([scanner scanUpToString:@"\"lng\" :" intoString:nil] && [scanner scanString:@"\"lng\" :" intoString:nil]) {
                [scanner scanDouble:&longitude];
            }
        }
    }
    CLLocationCoordinate2D center;
    center.latitude = latitude;
    center.longitude = longitude;
    return center;
}

- (void)updateFromToMarkersLocations {
    
    if (!self.frommarker) {
        self.frommarker =  [[GMSMarker alloc] init];
        self.frommarker.map = self.mapView;
        self.frommarker.icon = [UIImage imageNamed:@"greenmarker@2x.png"];
    }
        self.frommarker.position = [self geoCodeUsingAddress:self.uitextfield_from.text];
    
    if (!self.tomarker) {
        self.tomarker =  [[GMSMarker alloc] init];
        self.tomarker.map = self.mapView;
        self.tomarker.icon = [UIImage imageNamed:@"redmarker@2x.png"];
    }
        self.tomarker.position = [self geoCodeUsingAddress:self.uitextfield_to.text];
    
    CLLocationCoordinate2D coordinateSouthWest = self.frommarker.position;
    CLLocationCoordinate2D coordinateNorthEast = self.tomarker.position;
    
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:coordinateSouthWest coordinate:coordinateNorthEast];
    
    if ([self.uitextfield_from.text length]>0 && [self.uitextfield_to.text length]>0)
        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds]];
}

//- (void)textFieldDidEndEditing:(UITextField *)textField {
//    NSLog(@"textFieldDidEndEditing");
//}
//
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //    NSLog(@"textFieldShouldReturn");
    [textField resignFirstResponder];
    [self updateFromToMarkersLocations];
    return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.uitextfield_from isFirstResponder] && [touch view] != self.uitextfield_from) {
        [self.uitextfield_from resignFirstResponder];
        [self updateFromToMarkersLocations];
    }
    if ([self.uitextfield_to isFirstResponder] && [touch view] != self.uitextfield_to) {
        [self.uitextfield_to resignFirstResponder];
        [self updateFromToMarkersLocations];
    }
    [super touchesBegan:touches withEvent:event];
}


- (void)startAnimation {
    self.CSAnimationView_Top.type = CSAnimationTypeSlideDown;
    self.CSAnimationView_Top.duration = 0.3;
    self.CSAnimationView_Top.delay = 0.00;
    [self.CSAnimationView_Top startCanvasAnimation];
    
    self.CSAnimationView_FromGo.type = CSAnimationTypeFadeIn;
    self.CSAnimationView_FromGo.duration = 0.3;
    self.CSAnimationView_FromGo.delay = 0.07;
    [self.CSAnimationView_FromGo startCanvasAnimation];
    
    self.CSAnimationView_Map.type = CSAnimationTypeFadeIn;
    self.CSAnimationView_Map.duration = 0.3;
    self.CSAnimationView_Map.delay = 0.14;
    [self.CSAnimationView_Map startCanvasAnimation];
    
    self.CSAnimationView_Top.alpha=1;
    self.CSAnimationView_FromGo.alpha=1;
    self.CSAnimationView_Map.alpha=1;
}

- (void)startAnimationToFadeEverything {
    self.CSAnimationView_Top.alpha=0;
    
    self.CSAnimationView_FromGo.alpha=0;
    
    self.CSAnimationView_Map.alpha=0;
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

- (IBAction)btn_switchFromAndTo:(id)sender {
    NSString *tmp = self.uitextfield_from.text;
    self.uitextfield_from.text = self.uitextfield_to.text;
    self.uitextfield_to.text = tmp;
    
    float latTmp = self.frommarker.position.latitude;
    float lngTmp = self.frommarker.position.longitude;
    self.frommarker.position = self.tomarker.position;
    self.tomarker.position = CLLocationCoordinate2DMake(latTmp, lngTmp);
}

- (IBAction)btn_leaveNow:(id)sender {
    
    if (viewStatus==ViewStatus_datepickerview) {
        viewStatus = ViewStatus_mapview;
    } else {
        viewStatus = ViewStatus_datepickerview;
    }
    [self UpdateViewByViewStatus];
}

- (IBAction)btn_search:(id)sender {
    viewStatus = ViewStatus_routeview;
    if ([statusView isDescendantOfView:self.view])
        return;
    statusView = [[StatusView alloc] initWithText:@"Searching routes..." delayToHide:0 iconIndex:0];
    [self.view addSubview:statusView];
    
    //
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setObject:[NSString stringWithFormat:@"%f", self.frommarker.position.latitude ] forKey:@"departureLat"];
    
    [param setObject:[NSString stringWithFormat:@"%f", self.frommarker.position.longitude ] forKey:@"departureLng"];
    [param setObject:[NSString stringWithFormat:@"%f", self.tomarker.position.latitude ] forKey:@"arrivalLat"];
    [param setObject:[NSString stringWithFormat:@"%f", self.tomarker.position.longitude ] forKey:@"arrivalLng"];
    
    if (self.segment_whentoleave.selectedSegmentIndex==0) {
        [param setObject:[NSString stringWithFormat:@"0"] forKey:@"departureTime"];
        [param setObject:[NSString stringWithFormat:@"0"] forKey:@"arrivalTime"];
    } else if (self.segment_whentoleave.selectedSegmentIndex==1) {
        NSTimeInterval  time = [self.uidatepicker.date timeIntervalSince1970]*1000;
        [param setObject:[NSString stringWithFormat:@"%.0f", time] forKey:@"departureTime"];
        [param setObject:[NSString stringWithFormat:@"0"] forKey:@"arrivalTime"];
    } else if (self.segment_whentoleave.selectedSegmentIndex==2) {
        NSTimeInterval  time = [self.uidatepicker.date timeIntervalSince1970]*1000;
        [param setObject:[NSString stringWithFormat:@"0"] forKey:@"departureTime"];
        [param setObject:[NSString stringWithFormat:@"%.0f", time] forKey:@"arrivalTime"];
    }
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:param
                                                       options:kNilOptions error:nil];
    NSString *jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //        NSLog(@"%@", jsonDataStr);
    
    NSString *function = [NSString stringWithFormat:@"start('%@')", jsonDataStr];
    //    NSString *function = [NSString stringWithFormat:@"myRouter.init()"];
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:function];
    result = @"";

}

- (IBAction)btn_route:(id)sender {
    [self updateFromToMarkersLocations];
    
    if([self.uitextfield_from.text length]==0 || [self.uitextfield_to.text length]==0)
        return;
    
    [statusView removeFromSuperview];
    if (viewStatus==ViewStatus_datepickerview || viewStatus == ViewStatus_routeview) {
        viewStatus = ViewStatus_mapview;
        [self.uibutton_search setTitle:@"Plan" forState:UIControlStateNormal];
        
    } else {
        viewStatus = ViewStatus_datepickerview;
        [self.uibutton_search setTitle:@"Cancel" forState:UIControlStateNormal];
        
    }
    [self UpdateViewByViewStatus];
}


-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    NSLog(@"shouldStartLoadWithRequest");
    
    NSString* urlString = [NSString stringWithFormat:@"%@",[[request URL] absoluteString]];
    if ([urlString hasPrefix:@"result:"]) {
        [statusView removeFromSuperview];
        
        urlString = [[self decodeFromPercentEscapeString: urlString] substringFromIndex: 19];
        
        route_dic = [NSJSONSerialization JSONObjectWithData:[urlString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        
        NSLog(@"route_dic %@", route_dic);
        
        localCalendarArray = [[NSMutableArray alloc] init];
        for(int i = 0; i<[[route_dic objectForKey:@"routes"] count]; i++) [localCalendarArray addObject: [NSNull null]];
//        [self.uibtn_addToCalendar setTitle:@"Add to Calendar" forState:UIControlStateNormal];
//        NSLog(@"route_count %ld",[[route_dic objectForKey:@"routes"] count]);
        
        [self.uitableview_routes reloadData];
        
        
        [self UpdateViewByViewStatus];
        
        return NO;
    } else {
        return YES;
    }
}

// Decode a percent escape encoded string.
- (NSString*) decodeFromPercentEscapeString:(NSString *) string {
    return (__bridge NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                         (__bridge CFStringRef) string,
                                                                                         CFSTR(""),
                                                                                         kCFStringEncodingUTF8);
}
- (IBAction)btn_recurring_no:(id)sender {
    viewStatus = ViewStatus_mapview;
    [self.uibutton_search setTitle:@"Plan" forState:UIControlStateNormal];
    [self UpdateViewByViewStatus];
}

- (IBAction)btn_recurring_yes:(id)sender {
    if ([statusView isDescendantOfView:self.view])
        return;
    statusView = [[StatusView alloc] initWithText:@"Added to Calendar" delayToHide:0.7 iconIndex:0];
    [self.view addSubview:statusView];
    
//    Calendar *localCalendar = [[Calendar alloc] initWithValues:self.uitextfield_from.text Address_to:self.uitextfield_to.text When_status:self.segment_whentoleave.selectedSegmentIndex When_time:[self.uidatepicker.date timeIntervalSince1970] Scheduled_departure_time:0 Scheduled_arrival_time:0 Scheduled_walking_time:0 Scheduled_total_time:0 Scheduled_details:@"" Scheduled_dictionary:@"" Whole_dictionary:@""];
    
    NSArray *subviews = [self.CSAnimationView_Recurring subviews];
//
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            if (subview.tag)
                if (subview.tag>0) {
                    UIButton *button = (UIButton *)subview;
                    NSLog(@"button: %ld",(long)button.tag);
                    
                    for (int i=1; i<=[self.uitextfield_days_recurring.text intValue]; i++) {
                        NSLog(@"r: %d",i);
                        NSDate *today = [NSDate dateWithTimeIntervalSince1970: [self.uidatepicker.date timeIntervalSince1970]];
                        today = [today dateByAddingTimeInterval:60*60*24*i ];
                        
                        NSCalendar *calendar = [NSCalendar currentCalendar];
                        NSDateComponents *components = [calendar components:NSCalendarUnitWeekday fromDate:today];
                        NSInteger weekday = [components weekday]-1;
                        if (weekday==0) weekday=7;
                        
                        if (button.tag>10)
                        if (((button.tag-10)%7)== weekday) {
//                            NSLog(@"weekday:%ld, %ld", ((button.tag-10)%7), (long)weekday);
                            NSLog(@"recurring: %d",i);
                    
                            NSString *query = [NSString stringWithFormat:@"INSERT INTO thub_plans (address_from, address_to, when_time, when_status) VALUES ('%@', '%@', %.0f, %ld)", self.uitextfield_from.text, self.uitextfield_to.text, [self.uidatepicker.date timeIntervalSince1970]+60*60*24*i, (long)self.segment_whentoleave.selectedSegmentIndex];
                    
                            [appDelegate.dbManager executeQuery:query];
                        }
                    }
                }
        }
    }
    
    viewStatus = ViewStatus_mapview;
    [self.uibutton_search setTitle:@"Plan" forState:UIControlStateNormal];
    [self UpdateViewByViewStatus];
}
@end
