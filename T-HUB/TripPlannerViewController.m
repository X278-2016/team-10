//
//  TripPlannerViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 5/11/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "TripPlannerViewController.h"
#import "ColorConstants.h"
#import "StatusView.h"
#import "SuggestedRoutesViewController.h"

enum ViewStatus {
    ViewStatus_mapview,
    ViewStatus_datepicker_leaveAt_view,
    ViewStatus_datepicker_arriveBy_view
};

static float alphaNumber = 0.87;

@interface TripPlannerViewController () {
    int isFirstTime;
    
    UIWebView *webView;
    
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    
    StatusView *statusView;
    
    // DatePicker
    NSTimeInterval nSTimeInterval_leaveAt;
    NSTimeInterval nSTimeInterval_arriveBy;
    enum ViewStatus viewStatus;
    
    
}


@property (strong, nonatomic) GMSMapView *mapView;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (strong, nonatomic) GMSMarker *marker;
@property (strong, nonatomic) GMSMarker *frommarker;
@property (strong, nonatomic) GMSMarker *tomarker;
@property (strong, nonatomic) GMSMarker *currentlyTappedMarker;
@property (strong, nonatomic) UIView *displayedInfoWindow;

@end



@implementation TripPlannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self startAnimationToFadeEverything];
    viewStatus = ViewStatus_mapview;
    
    [self initWebview];
    
    
    self.uITextField_from.text = @"1025 16th Ave S #102 Nashville, TN 37212";
    self.uITextField_to.text = @"2126 Abbott Martin Rd Nashville, TN 37215";
    
    nSTimeInterval_leaveAt=0;
    nSTimeInterval_arriveBy=0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self UpdateViewByViewStatus];
    
    [self initMap];
    
    [self startAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self startAnimationToFadeEverything];
}

-(void)initMap {
    [self getCurrentLocation];
    
    geocoder = [[CLGeocoder alloc] init];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.locationManager.location.coordinate.latitude longitude:self.locationManager.location.coordinate.longitude zoom:12];
    self.mapView = [GMSMapView mapWithFrame:self.cSAnimationView_base.bounds camera:camera];
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    [self.cSAnimationView_base addSubview:self.mapView];
    
    // My Location
    UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [myButton addTarget:self action:@selector(myLocation:) forControlEvents:UIControlEventTouchUpInside];
    [myButton setBackgroundImage:[UIImage imageNamed:@"location_icon@2x.png"] forState:UIControlStateNormal];
    myButton.frame = CGRectMake(self.cSAnimationView_base.frame.size.width-32-29.0, 224, 32.0, 32.0);
    myButton.alpha = 0.87;
    
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.cSAnimationView_base addSubview:myButton];
        [self updateFromToMarkersLocations];
    });
}

- (void)myLocation:(UIButton *)sender {
    [self.mapView animateToLocation:self.locationManager.location.coordinate];
}

- (void)initWebview {
    webView = [[UIWebView alloc] init];
    webView.delegate = self;
    //    [webView loadHTMLString:@"<script src=\"calc.js\"></script>" baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GoogleMap" ofType:@"html"]isDirectory:NO]]];
}

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
    
    [self.cSAnimationView_base addSubview:self.displayedInfoWindow];
    
    [self.view bringSubviewToFront:self.cSAnimationView_locationsAndTime];
    [self.view bringSubviewToFront:self.cSAnimationView_plan_button];
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
            self.uITextField_from.text = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
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
            self.uITextField_to.text = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
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
    self.frommarker.position = [self geoCodeUsingAddress:self.uITextField_from.text];
    
    if (!self.tomarker) {
        self.tomarker =  [[GMSMarker alloc] init];
        self.tomarker.map = self.mapView;
        self.tomarker.icon = [UIImage imageNamed:@"redmarker@2x.png"];
    }
    self.tomarker.position = [self geoCodeUsingAddress:self.uITextField_to.text];
    
//    CLLocationCoordinate2D coordinateSouthWest = self.frommarker.position;
//    CLLocationCoordinate2D coordinateNorthEast = self.tomarker.position;
    
//    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:coordinateSouthWest coordinate:coordinateNorthEast];
    
//    if ([self.uITextField_from.text length]>0 && [self.uITextField_to.text length]>0)
//        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds]];
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
    if ([self.uITextField_from isFirstResponder] && [touch view] != self.uITextField_from) {
        [self.uITextField_from resignFirstResponder];
        [self updateFromToMarkersLocations];
    }
    if ([self.uITextField_to isFirstResponder] && [touch view] != self.uITextField_to) {
        [self.uITextField_to resignFirstResponder];
        [self updateFromToMarkersLocations];
    }
    [super touchesBegan:touches withEvent:event];
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

- (void)startAnimation {
    self.cSAnimationView_base.alpha = 1;
    [self.cSAnimationView_base bringSubviewToFront:self.cSAnimationView_locationsAndTime];
    [self.cSAnimationView_base bringSubviewToFront:self.cSAnimationView_plan_button];
    
    self.cSAnimationView_locationsAndTime.type = CSAnimationTypeBounceDown;
    self.cSAnimationView_locationsAndTime.duration = 0.3;
    self.cSAnimationView_locationsAndTime.delay = 0.1;
    [self.cSAnimationView_locationsAndTime startCanvasAnimation];
    
    self.cSAnimationView_plan_button.type = CSAnimationTypeFadeIn;
    self.cSAnimationView_plan_button.duration = 0.3;
    self.cSAnimationView_plan_button.delay = 0.4;
    [self.cSAnimationView_plan_button startCanvasAnimation];
    
    self.cSAnimationView_locationsAndTime.alpha=alphaNumber;
    self.cSAnimationView_plan_button.alpha=alphaNumber;
}

- (void)startAnimationToFadeEverything {
    self.cSAnimationView_base.alpha = 0;
    self.cSAnimationView_locationsAndTime.alpha=0;
    
    self.cSAnimationView_plan_button.alpha=0;
    
    self.cSAnimationView_datePicker.alpha=0;
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

- (void)UpdateViewByViewStatus {
    switch (viewStatus) {
        case ViewStatus_mapview: {
            self.cSAnimationView_datePicker.hidden = YES;
            self.cSAnimationView_locationsAndTime.alpha = alphaNumber;
            
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"MM-dd hh:mma"];
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [df setLocale:locale];
            
            if (nSTimeInterval_leaveAt>0) {
                [self.uIButton_leaveNow setBackgroundColor: DefaultGreen];
                [self.uIButton_leaveNow setTitle:[df stringFromDate: [NSDate dateWithTimeIntervalSince1970:nSTimeInterval_leaveAt ]] forState:UIControlStateNormal];
            } else
                [self.uIButton_leaveNow setBackgroundColor: [UIColor lightGrayColor]];
            if (nSTimeInterval_arriveBy>0) {
                [self.uIButton_arriveAt setBackgroundColor: DefaultGreen];
                [self.uIButton_arriveAt setTitle:[df stringFromDate: [NSDate dateWithTimeIntervalSince1970:nSTimeInterval_arriveBy ]] forState:UIControlStateNormal];
            } else
                [self.uIButton_arriveAt setBackgroundColor: [UIColor lightGrayColor]];
            
        
            self.mapView.userInteractionEnabled = YES;

            break;
        }
        case ViewStatus_datepicker_leaveAt_view: {
            self.cSAnimationView_datePicker.hidden = NO;
            self.cSAnimationView_datePicker.alpha = 1;
            self.cSAnimationView_locationsAndTime.alpha = 1;
            self.mapView.userInteractionEnabled = NO;
            
            [self.cSAnimationView_base bringSubviewToFront:self.cSAnimationView_datePicker];
            self.cSAnimationView_datePicker.type = CSAnimationTypePop;
            self.cSAnimationView_datePicker.duration = 0.3;
            self.cSAnimationView_datePicker.delay = 0.0;
            [self.cSAnimationView_datePicker startCanvasAnimation];
            
            NSDate *currentDate = [NSDate date];
            [self.uIDatePicker_datePicker setMinimumDate:currentDate];
            
            [self.uIButton_leaveNow setBackgroundColor:DefaultYellow];
            if (nSTimeInterval_leaveAt>0) {
                [self.uIDatePicker_datePicker setDate: [NSDate dateWithTimeIntervalSince1970: nSTimeInterval_leaveAt]];
            }
            [self.uIButton_leaveNow setTitle:@"Set Time" forState:UIControlStateNormal];
            break;
        }
        case ViewStatus_datepicker_arriveBy_view: {
            self.cSAnimationView_datePicker.hidden = NO;
            self.cSAnimationView_datePicker.alpha = 1;
            self.cSAnimationView_locationsAndTime.alpha = 1;
            self.mapView.userInteractionEnabled = NO;
            
            [self.cSAnimationView_base bringSubviewToFront:self.cSAnimationView_datePicker];
            self.cSAnimationView_datePicker.type = CSAnimationTypePop;
            self.cSAnimationView_datePicker.duration = 0.3;
            self.cSAnimationView_datePicker.delay = 0.0;
            [self.cSAnimationView_datePicker startCanvasAnimation];
            
            NSDate *currentDate = [NSDate date];
            [self.uIDatePicker_datePicker setMinimumDate:currentDate];
            
            [self.uIButton_arriveAt setBackgroundColor:DefaultYellow];
            if (nSTimeInterval_arriveBy>0) {
                [self.uIDatePicker_datePicker setDate: [NSDate dateWithTimeIntervalSince1970: nSTimeInterval_arriveBy]];
            }
            [self.uIButton_arriveAt setTitle:@"Set Time" forState:UIControlStateNormal];
            break;

        }
        default:
            break;
    }
}


- (IBAction)didTapLeaveNow:(id)sender {
    if (viewStatus==ViewStatus_datepicker_arriveBy_view)
        return;
    
    if (viewStatus==ViewStatus_mapview) {
        viewStatus=ViewStatus_datepicker_leaveAt_view;
        [self UpdateViewByViewStatus];
    } else {
        viewStatus=ViewStatus_mapview;
        [self UpdateViewByViewStatus];
    }
}
- (IBAction)didTapArriveAt:(id)sender {
    if (viewStatus==ViewStatus_datepicker_leaveAt_view)
        return;
    
    if (viewStatus==ViewStatus_mapview) {
        viewStatus=ViewStatus_datepicker_arriveBy_view;
        [self UpdateViewByViewStatus];
    } else {
        viewStatus=ViewStatus_mapview;
        [self UpdateViewByViewStatus];
    }
}
- (IBAction)didTapDatePicker_cancel:(id)sender {
    if (viewStatus==ViewStatus_datepicker_leaveAt_view)
        nSTimeInterval_leaveAt = 0;
    else if (viewStatus==ViewStatus_datepicker_arriveBy_view)
        nSTimeInterval_arriveBy = 0;
    
    viewStatus=ViewStatus_mapview;
    [self UpdateViewByViewStatus];
}

- (IBAction)didTapDatePicker_done:(id)sender {
    if (viewStatus==ViewStatus_datepicker_leaveAt_view)
        nSTimeInterval_leaveAt = [self.uIDatePicker_datePicker.date timeIntervalSince1970];
    else if (viewStatus==ViewStatus_datepicker_arriveBy_view)
        nSTimeInterval_arriveBy = [self.uIDatePicker_datePicker.date timeIntervalSince1970];
    
    viewStatus=ViewStatus_mapview;
    [self UpdateViewByViewStatus];
}

- (IBAction)didTapGoPlanning:(id)sender {
//    [self updateFromToMarkersLocations];
    
    if ([statusView isDescendantOfView:self.view])
        return;
    statusView = [[StatusView alloc] initWithText:@"Planning routes..." delayToHide:0 iconIndex:0];
    [self.view addSubview:statusView];
    
    //
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setObject:[NSString stringWithFormat:@"%f", self.frommarker.position.latitude ] forKey:@"departureLat"];
    [param setObject:[NSString stringWithFormat:@"%f", self.frommarker.position.longitude ] forKey:@"departureLng"];
    [param setObject:[NSString stringWithFormat:@"%f", self.tomarker.position.latitude ] forKey:@"arrivalLat"];
    [param setObject:[NSString stringWithFormat:@"%f", self.tomarker.position.longitude ] forKey:@"arrivalLng"];
    
    [param setObject:[NSString stringWithFormat:@"%.0f", nSTimeInterval_leaveAt*1000] forKey:@"departureTime"];
    [param setObject:[NSString stringWithFormat:@"%.0f", nSTimeInterval_arriveBy*1000] forKey:@"arrivalTime"];
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:param
                                                       options:kNilOptions error:nil];
    NSString *jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //        NSLog(@"%@", jsonDataStr);
    
    NSString *function = [NSString stringWithFormat:@"start('%@')", jsonDataStr];
    //    NSString *function = [NSString stringWithFormat:@"myRouter.init()"];
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:function];
    result = @"";

}


-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    NSLog(@"shouldStartLoadWithRequest");
    
    NSString* urlString = [NSString stringWithFormat:@"%@",[[request URL] absoluteString]];
    if ([urlString hasPrefix:@"result:"]) {
        [statusView removeFromSuperview];
        
        urlString = [[self decodeFromPercentEscapeString: urlString] substringFromIndex: 19];
        
        NSMutableDictionary *route_dic = [NSJSONSerialization JSONObjectWithData:[urlString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        
        NSLog(@"route_dic %@", route_dic);
//        
//        localCalendarArray = [[NSMutableArray alloc] init];
//        for(int i = 0; i<[[route_dic objectForKey:@"routes"] count]; i++) [localCalendarArray addObject: [NSNull null]];
        //        [self.uibtn_addToCalendar setTitle:@"Add to Calendar" forState:UIControlStateNormal];
        //        NSLog(@"route_count %ld",[[route_dic objectForKey:@"routes"] count]);
        
//        [self.uitableview_routes reloadData];
        
        SuggestedRoutesViewController *suggestedRoutesViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SuggestedRoutesViewController"];
        [self presentViewController:suggestedRoutesViewController animated:NO completion:nil];
        
        
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
@end
