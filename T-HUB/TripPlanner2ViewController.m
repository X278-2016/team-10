//
//  TripPlanner2ViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 5/12/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "TripPlanner2ViewController.h"
#import "ColorConstants.h"
#import "StatusView.h"
#import "SuggestedRoutesViewController.h"
#import "AppDelegate.h"
#import "ComingBusTableViewCell.h"

#import "AFNetworking.h"
#import <ProtocolBuffers/ProtocolBuffers.h>
#import "GtfsRealtime.pb.h"

#import "CommonAPI.h"
#import "SearchHistory.H"

enum ViewStatus {
    ViewStatus_mapview,
    ViewStatus_mapview_locationDetermined,
    ViewStatus_planview,
    ViewStatus_planview_locationDetermined
};

@interface TripPlanner2ViewController () {
    
    UIWebView *webView;
    UIWebView *webView_address;
    UIWebView *webView_autocomplete;
    GMSPolyline *polyline_from_to;
    
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    
    enum ViewStatus viewStatus;
    
    CLLocationCoordinate2D center_coordinate;
    
    // DatePicker
    NSTimeInterval nSTimeInterval_leaveAt;
    NSTimeInterval nSTimeInterval_arriveBy;
    
    StatusView *statusView;
    
    AppDelegate *appDelegate;
    
    NSMutableDictionary *nearbyBuses;
    
    NSMutableDictionary *param;
    
    Boolean firstTimeFlag;
    Boolean firstTimeFlag_searchHistory;
    
    float fakeLat;
    float fakeLon;
    BOOL fakeLocationFlag;
    
    NSArray *array_searchHistory;
    NSManagedObjectContext* objectContext;
    
    UITextField *activeTextField;
    NSTimer *nSTimer_timeout;
    
    BOOL flag_addressEnteredInMapView;
    NSTimer *nSTimer_autocomplete;
}

@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSMarker *frommarker;
@property (strong, nonatomic) GMSMarker *tomarker;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nSLayoutConstraint_cSAnimtionView_searchBar_height;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nSLayoutConstraint_bar1_right_horizontal;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nSLayoutConstraint_cSAnimtionView_comingBuses_height;


@end



@implementation TripPlanner2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self hideEverything];
    flag_addressEnteredInMapView = NO;
    self.cSAnimationView_datePicker.hidden = YES;
    nSTimeInterval_leaveAt=0;
    nSTimeInterval_arriveBy=0;
    firstTimeFlag = YES;
    firstTimeFlag_searchHistory = YES;
    
    [self initWebviews];
    // Do any additional setup after loading the view.
    
    self.uITextField_topSearchBar.delegate = self;
    self.uITextField_topSearchBar.returnKeyType = UIReturnKeyDone;
    self.uITextField_topSearchBar2.delegate = self;
    self.uITextField_topSearchBar2.returnKeyType = UIReturnKeyDone;
    
    [self.uITextField_topSearchBar addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
    [self.uITextField_topSearchBar2 addTarget:self
                                      action:@selector(textFieldDidChange:)
                            forControlEvents:UIControlEventEditingChanged];
    
    //    self.uITextField_topSearchBar.text = @"2324 crestmoor rd, nashville";
    //    self.uITextField_topSearchBar2.text = @"3906 west end ave, nashville";
    
    // AppDelegate
    appDelegate = ((AppDelegate*)[[UIApplication sharedApplication]delegate]);
    
    [self getGasPriceUpdate];
    objectContext = [CoreDataHelper managedObjectContext];
    
    self.cSAV_searchHistory.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (firstTimeFlag_searchHistory) {
        self.cSAnimationView_datePicker.hidden = YES;
        self.uIButton_depart.enabled = YES;
        self.uIButton_arrive.enabled = YES;
        self.uIButton_startFromHere.enabled = YES;
        self.uIButton_EndAtHere.enabled = YES;
        
        nSTimeInterval_leaveAt=0;
        nSTimeInterval_arriveBy=0;
        
    }
    
//    [self.uIButton_depart setBackgroundColor: DefaultGreen];
//    [self.uIButton_depart setTitle:@"Depart Now" forState:UIControlStateNormal];
//    [self.uIButton_arrive setBackgroundColor: [UIColor lightGrayColor]];
//    [self.uIButton_arrive setTitle:@"Arrival Time" forState:UIControlStateNormal];
    
    
    fakeLat = 36.165546;
    fakeLon = -86.777033;
    fakeLocationFlag = NO;
    if ([defaults objectForKey:@"demoMode"])
        if ([[defaults objectForKey:@"demoMode"] boolValue])
            fakeLocationFlag = YES;
    
    if (firstTimeFlag_searchHistory) {
        self.frommarker=nil;
        self.tomarker=nil;
        [self initMap];
    }
    
    if (fakeLocationFlag) {
        GMSMarker *marker2 = [[GMSMarker alloc] init];
        
        marker2.title = @"";
        marker2.icon = [UIImage imageNamed:@"fakeLocationMarker"];
        marker2.position = CLLocationCoordinate2DMake(fakeLat, fakeLon);
        marker2.map = self.mapView;
        
        CLLocationCoordinate2D center;
        center.latitude = fakeLat;
        center.longitude = fakeLon;
        
        [self.mapView animateToLocation:center];
    }
    
    if (firstTimeFlag_searchHistory) {
        [self initialViews];
    }
    
    if (appDelegate.reschedule_route_dictionary) {
        
        viewStatus = ViewStatus_planview_locationDetermined;
        [self UpdateViewByViewStatus];
        
        self.uITextField_topSearchBar.text = [appDelegate.reschedule_route_dictionary objectForKey:@"fromAddress" ];
        self.uITextField_topSearchBar2.text = [appDelegate.reschedule_route_dictionary objectForKey:@"toAddress" ];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"MM-dd HH:mm"];
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [df setLocale:locale];
        
        nSTimeInterval_leaveAt = [[appDelegate.reschedule_route_dictionary objectForKey:@"departureTime" ] intValue];
        nSTimeInterval_arriveBy = [[appDelegate.reschedule_route_dictionary objectForKey:@"arrivalTime" ] intValue];
        
        if (nSTimeInterval_leaveAt==0) {
            [self.uIButton_depart setBackgroundColor: [UIColor lightGrayColor]];
            [self.uIButton_depart setTitle:@"Depart Time" forState:UIControlStateNormal];
        } else {
            [self.uIButton_depart setBackgroundColor: DefaultGreen];
            [self.uIButton_depart setTitle:[df stringFromDate: [NSDate dateWithTimeIntervalSince1970:nSTimeInterval_leaveAt ]] forState:UIControlStateNormal];
        }
        
        if (nSTimeInterval_arriveBy==0) {
            [self.uIButton_arrive setBackgroundColor: [UIColor lightGrayColor]];
            [self.uIButton_arrive setTitle:@"Arrival Time" forState:UIControlStateNormal];
        } else {
            [self.uIButton_arrive setBackgroundColor: DefaultGreen];
            [self.uIButton_arrive setTitle:[df stringFromDate: [NSDate dateWithTimeIntervalSince1970:nSTimeInterval_arriveBy ]] forState:UIControlStateNormal];
        }
        
        self.frommarker.map = nil;
        self.frommarker = [[GMSMarker alloc] init];
        self.frommarker.title = @"";
        self.frommarker.icon = [UIImage imageNamed:@"start_marker@2x.png"];
        self.frommarker.position = CLLocationCoordinate2DMake([[appDelegate.reschedule_route_dictionary objectForKey:@"departureLat" ] doubleValue], [[appDelegate.reschedule_route_dictionary objectForKey:@"departureLng" ] doubleValue]);
        self.frommarker.map = self.mapView;
        self.tomarker.map = nil;
        self.tomarker = [[GMSMarker alloc] init];
        self.tomarker.title = @"";
        self.tomarker.icon = [UIImage imageNamed:@"end_marker@2x.png"];
        self.tomarker.position = CLLocationCoordinate2DMake([[appDelegate.reschedule_route_dictionary objectForKey:@"arrivalLat" ] doubleValue], [[appDelegate.reschedule_route_dictionary objectForKey:@"arrivalLng" ] doubleValue]);
        self.tomarker.map = self.mapView;
        [self drawRouteBetweenFromAndTo];
        
        self.cSAnimationView_centerMarker.alpha=0;
        
        appDelegate.reschedule_route_dictionary = nil;
    } else {
        if (firstTimeFlag_searchHistory) {
            viewStatus = ViewStatus_mapview;
            [self UpdateViewByViewStatus];
        } else {
            [self UpdateViewByViewStatus];
        }
    }
    
    self.uITableView_comingBuses.backgroundColor = [UIColor clearColor];
    
    firstTimeFlag_searchHistory = NO;
    
}

- (void)loadSearchHistory {
    NSArray* items = [CoreDataHelper fetchEntitiesForClass:[SearchHistory class] withPredicate:nil inManagedObjectContext:objectContext];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp"
                                                                 ascending:NO];
    array_searchHistory = [items sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
    if ([array_searchHistory count]>10) {
        array_searchHistory = [array_searchHistory subarrayWithRange:NSMakeRange(0, 10)];
    }
    self.uILabel_searchHistory_title.text = @"  SEARCH HISTORY";
    self.uILabel_searchHistory_title.backgroundColor = DefaultYellow;
}

-(void)viewDidDisappear:(BOOL)animated {
}

- (void)textFieldDidChange:(UITextField *)textField {
    [nSTimer_autocomplete invalidate];
    nSTimer_autocomplete=nil;
    
    if (textField.text.length>0) {
        NSMutableDictionary *map_userInfo = [[NSMutableDictionary alloc] init];
        [map_userInfo setObject:[NSNumber numberWithInteger:textField.tag] forKey:@"tag"];
        nSTimer_autocomplete = [NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(requestAutoComplete:) userInfo:map_userInfo repeats:NO];
    } else {
        [self loadSearchHistory];
        [self.uITableView_searchHistory reloadData];
    }
}
- (void)requestAutoComplete:(NSTimer *)timer {
    NSMutableDictionary *map_request = [[NSMutableDictionary alloc] init];
    int tag = [[[timer userInfo] objectForKey:@"tag"] intValue];
    if (tag==1) {
        [map_request setValue:self.uITextField_topSearchBar.text forKey:@"address"];
    } else {
        [map_request setValue:self.uITextField_topSearchBar2.text forKey:@"address"];
    }
    [map_request setValue:[NSNumber numberWithInt:tag] forKey:@"tag"];
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:map_request
                                                       options:kNilOptions error:nil];
    NSString *jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *function = [NSString stringWithFormat:@"start('%@')", jsonDataStr];
    NSString *result = [webView_autocomplete stringByEvaluatingJavaScriptFromString:function];
    result = @"";
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self loadSearchHistory];
//    NSLog(@"textFieldShouldBeginEditing: %@", textField.text);
    [self.uITableView_searchHistory reloadData];
    [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAV_searchHistory];
    self.cSAV_searchHistory.hidden = NO;
    self.cSAV_searchHistory.type = CSAnimationTypeFadeIn;
    self.cSAV_searchHistory.duration = 0.3;
    self.cSAV_searchHistory.delay = 0.0;
    [self.cSAV_searchHistory startCanvasAnimation];
    self.cSAV_searchHistory.alpha = 0.85;
    
    activeTextField = textField;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
//    NSLog(@"textFieldShouldEndEditing: %@", textField.text);
    if ([textField isEqual:activeTextField])
        self.cSAV_searchHistory.hidden = YES;
    return YES;
}

-(void)getGasPriceUpdate {
    
    NSURL *URL = [NSURL URLWithString:@"http://www.fueleconomy.gov/ws/rest/fuelprices"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // here we must create NSData object with received data...
        
        NSData *data = [[NSData alloc] initWithData:responseObject];
        NSString* responseXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSRange range = [responseXML rangeOfString:@"<regular>"];
        NSRange range2 = [responseXML rangeOfString:@"</regular>"];
        
        if (range.location!=NSNotFound && range2.location!=NSNotFound) {
            range.length = range2.location-range.location-9;
            range.location += 9;
            NSString *price = [responseXML substringWithRange:range];
            
            NSNumber *price_int = [NSNumber numberWithInt:[price intValue]];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            [defaults setObject:price_int forKey:@"gasPrice"];
            [defaults synchronize];
        } else {
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error (getGasPriceUpdate) : %@", [error localizedDescription]);
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
    // Hide nearby buses for now in the trip planner
    if (array_searchHistory) {
        return [array_searchHistory count];
    } else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchHistoryCell"];
    SearchHistory *searchHistory = [array_searchHistory objectAtIndex:indexPath.row];
    cell.textLabel.text = searchHistory.address;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.uITableView_searchHistory deselectRowAtIndexPath:indexPath animated:YES];
    SearchHistory *searchHistory = [array_searchHistory objectAtIndex:indexPath.row];
    activeTextField.text = searchHistory.address;
    NSLog(@"948:%@, %@", activeTextField.text, searchHistory.address);
    self.cSAV_searchHistory.hidden = YES;
    [self textFieldShouldReturn:activeTextField];
    return;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 35;
}


- (void)initWebviews {
    webView = [[UIWebView alloc] init];
    webView.delegate = self;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GoogleMap" ofType:@"html"]isDirectory:NO]]];
    webView_address = [[UIWebView alloc] init];
    webView_address.delegate = self;
    [webView_address loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GoogleMap_address" ofType:@"html"]isDirectory:NO]]];
    webView_autocomplete = [[UIWebView alloc] init];
    webView_autocomplete.delegate = self;
    [webView_autocomplete loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GoogleMap_autocomplete" ofType:@"html"]isDirectory:NO]]];
}

-(void)updateCenterMarkersLocation {
    
    geocoder = [[CLGeocoder alloc] init];
    
    // Auto append "Nashville, TN, USA"
    NSString *searchText = self.uITextField_topSearchBar.text;
    if ([self.uITextField_topSearchBar.text rangeOfString:@"vanderbilt"].location != NSNotFound || [self.uITextField_topSearchBar.text rangeOfString:@"Vanderbilt"].location != NSNotFound) {
        NSLog(@"Auto append");
        searchText = [self.uITextField_topSearchBar.text stringByAppendingString:@", Nashville, TN, USA"];
    }
    [geocoder geocodeAddressString:searchText completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            CLPlacemark *placemark2 = [placemarks lastObject];
            
            CLLocationCoordinate2D center;
            center.latitude = placemark2.location.coordinate.latitude;
            center.longitude = placemark2.location.coordinate.longitude;
            
            [self.mapView animateToLocation:center];
        }
    }];
}

- (void)formatAddress:(NSString *)address withTextFieldTag:(int) tag {
    NSLog(@"- (void)formatAddress:(NSString *)address withTextFieldTag:(int) tag {");
//    NSMutableDictionary *map_request = [[NSMutableDictionary alloc] init];
//    [map_request setValue:address forKey:@"address"];
//    [map_request setValue:[NSString stringWithFormat:@"%d", tag] forKey:@"tag"];
//    
//    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:map_request
//                                                       options:kNilOptions error:nil];
//    NSString *jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSString *function = [NSString stringWithFormat:@"start('%@')", jsonDataStr];
//    NSString *result = [webView_address stringByEvaluatingJavaScriptFromString:function];
//    result = @"";
}

- (void)updateFromToMarkersLocations {
    
    if (!self.frommarker) {
        self.frommarker.map = nil;
        self.frommarker = [[GMSMarker alloc] init];
        self.frommarker.title = @"";
        self.frommarker.icon = [UIImage imageNamed:@"start_marker@2x.png"];
    }
    geocoder = [[CLGeocoder alloc] init];
    
    [geocoder geocodeAddressString:self.uITextField_topSearchBar.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
//            NSLog(@"uITextField_topSearchBar");
            CLPlacemark *placemark2 = [placemarks lastObject];
            
            CLLocationCoordinate2D center;
            center.latitude = placemark2.location.coordinate.latitude;
            center.longitude = placemark2.location.coordinate.longitude;
            
            self.frommarker.position = center;
            
            if (self.frommarker && self.tomarker) {
                [self drawRouteBetweenFromAndTo];
            }
        }
    }];
    
    if (!self.tomarker) {
        self.tomarker.map = nil;
        self.tomarker = [[GMSMarker alloc] init];
        self.tomarker.title = @"";
        self.tomarker.icon = [UIImage imageNamed:@"end_marker@2x.png"];
    }
    CLGeocoder *geocoder2 = [[CLGeocoder alloc] init];
    [geocoder2 geocodeAddressString:self.uITextField_topSearchBar2.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
//            NSLog(@"uITextField_topSearchBar2");
            CLPlacemark *placemark2 = [placemarks lastObject];
            
            CLLocationCoordinate2D center;
            center.latitude = placemark2.location.coordinate.latitude;
            center.longitude = placemark2.location.coordinate.longitude;
            
            self.tomarker.position = center;
            
            if (self.frommarker && self.tomarker) {
                [self drawRouteBetweenFromAndTo];
            }
        }
    }];
}

- (void) mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    // Hide keyboard
    [self.uITextField_topSearchBar resignFirstResponder];
    [self.uITextField_topSearchBar2 resignFirstResponder];
    
    self.cSAnimationView_centerMarker.alpha=1;
    
    if (viewStatus==ViewStatus_mapview_locationDetermined) {
        viewStatus=ViewStatus_mapview;
    } else if (viewStatus==ViewStatus_planview_locationDetermined) {
        viewStatus=ViewStatus_planview;
    }
    [self UpdateViewByViewStatus];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
//    NSLog(@"1119:textFieldShouldReturn");
//    NSLog(@"957:%@", self.cSAV_searchHistory.hidden?@"HIDDEN":@"VISIBLE");
//    if (array_searchHistory.count>0 && [self.uILabel_searchHistory_title.text rangeOfString:@"HISTORY"].location==NSNotFound) {
//        return NO;
////        SearchHistory *searchHistory = [array_searchHistory objectAtIndex:0];
////        textField.text = searchHistory.address;
//    }
    
    if (viewStatus==ViewStatus_mapview || viewStatus==ViewStatus_mapview_locationDetermined) {
        [self updateCenterMarkersLocation];
        flag_addressEnteredInMapView = YES;
//        NSLog(@"1120:textFieldShouldReturn");
    } else {
        [self updateFromToMarkersLocations];
//        NSLog(@"1121:textFieldShouldReturn");
    }
//    [self formatAddress:textField.text withTextFieldTag:(int)textField.tag];
    return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.uITextField_topSearchBar isFirstResponder] && [touch view] != self.uITextField_topSearchBar) {
        [self.uITextField_topSearchBar resignFirstResponder];
        if (viewStatus==ViewStatus_mapview || viewStatus==ViewStatus_mapview_locationDetermined) {
            [self updateCenterMarkersLocation];
        } else {
            [self updateFromToMarkersLocations];
        }
    }
    if ([self.uITextField_topSearchBar2 isFirstResponder] && [touch view] != self.uITextField_topSearchBar2) {
        [self.uITextField_topSearchBar2 resignFirstResponder];
        if (viewStatus==ViewStatus_mapview || viewStatus==ViewStatus_mapview_locationDetermined) {
            [self updateCenterMarkersLocation];
        } else {
            [self updateFromToMarkersLocations];
        }
    }
    [super touchesBegan:touches withEvent:event];
}

- (void) mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    NSLog(@"idleAtCameraPosition");
    
    CGPoint point = mapView.center;
    CLLocationCoordinate2D coor = [mapView.projection coordinateForPoint:point];
    center_coordinate = coor;
    
    CLLocation *sectorLocation = [[CLLocation alloc] initWithLatitude:coor.latitude longitude:coor.longitude];
    
    
    [geocoder reverseGeocodeLocation:sectorLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error == nil && [placemarks count] > 0) {
            if (viewStatus==ViewStatus_mapview) {
                viewStatus=ViewStatus_mapview_locationDetermined;
            } else if (viewStatus==ViewStatus_planview) {
                viewStatus=ViewStatus_planview_locationDetermined;
            }
            [self UpdateViewByViewStatus];
            
            if ((viewStatus==ViewStatus_mapview || viewStatus==ViewStatus_mapview_locationDetermined) && !flag_addressEnteredInMapView) {
                placemark = [placemarks lastObject];
                if (placemark.subThoroughfare.length==0 || placemark.thoroughfare.length==0)
                    self.uITextField_topSearchBar.text = [[NSString stringWithFormat:@"%@, %@ %@",
                                                            placemark.locality, placemark.administrativeArea,
                                                            placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
                else
                    self.uITextField_topSearchBar.text = [[NSString stringWithFormat:@"%@ %@, %@, %@ %@",
                                                       placemark.subThoroughfare, placemark.thoroughfare,
                                                       placemark.locality, placemark.administrativeArea,
                                                       placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
            }
            flag_addressEnteredInMapView = NO;
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
}

- (void)initialViews {
    [self.uITextField_topSearchBar setLeftViewMode:UITextFieldViewModeAlways];
    self.uITextField_topSearchBar.leftView= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search-icon@2x.png"]];
    [self.uITextField_topSearchBar2 setLeftViewMode:UITextFieldViewModeAlways];
    self.uITextField_topSearchBar2.leftView= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search-icon@2x.png"]];
    
    [self.uIButton_startFromHere.imageView setImage:[UIImage imageNamed:@"idle_marker_for_button@2x.png"]];
    [self.uIButton_EndAtHere.imageView setImage:[UIImage imageNamed:@"idle_marker_for_button@2x.png"]];
    
    self.nSLayoutConstraint_cSAnimtionView_comingBuses_height.constant=45;
    
    
}

- (void)hideEverything {
    self.cSAnimationView_topSearchBar.hidden=YES;
    self.cSAnimationView_setStartEnd.hidden=YES;
    self.cSAnimationView_commingBuses.hidden=YES;
    self.cSAnimationView_datePicker.hidden=YES;
    self.cSAnimationView_myLocation.hidden=YES;
}

-(void)getTripUpdate:(NSMutableDictionary *)stops_dic {
    
    nearbyBuses = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    NSURL *URL;
    URL=[NSURL URLWithString:@"https://129.59.105.175/static/Data/Feed/tripupdates.pb"];
    URL = [NSURL URLWithString:@"http://transitdata.nashvillemta.org/TMGTFSRealTimeWebService/tripupdate/tripupdates.pb"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    //    NSString *fileName = [URL lastPathComponent];
    
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // here we must create NSData object with received data...
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
        // NSLog(@"feedMessage.entity: %@ ", feedMessage.entity);
        
        if (feedMessage)
            for (FeedEntity *feedEntity in feedMessage.entity) {
                
                for (TripUpdateStopTimeUpdate *tripUpdateStopTimeUpdate in feedEntity.tripUpdate.stopTimeUpdate) {
                    NSString *stopId = tripUpdateStopTimeUpdate.stopId;
                    if ([stops_dic objectForKey:stopId]!=nil) {
                        TripDescriptor *tripDescriptor = feedEntity.tripUpdate.trip;
                        
                        //                    NSLog(@"getTripUpdate:::%@, %@", stopId, tripDescriptor.tripId);
                        TripUpdateStopTimeEvent *event = tripUpdateStopTimeUpdate.departure;
                        
                        NSMutableDictionary *one_route = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects: stopId, tripDescriptor.tripId, [NSString stringWithFormat:@"%lld", event.time ], nil] forKeys:[NSArray arrayWithObjects: @"stop_id", @"trip_id", @"time", nil]];
                        
                        int time_now = [[NSDate date] timeIntervalSince1970];
                        
                        if ([[one_route objectForKey:@"time"] intValue]<=time_now) continue;
                        
                        if ([nearbyBuses objectForKey: tripDescriptor.routeId]!=nil) {
                            NSString *stopId2 = [[nearbyBuses objectForKey: tripDescriptor.routeId] objectForKey:@"stop_id"];
                            float distance1= [[[stops_dic objectForKey:stopId2] objectForKey:@"stop_distance"] floatValue];
                            float distance2= [[[stops_dic objectForKey:stopId] objectForKey:@"stop_distance"] floatValue];
                            
                            if (distance1>distance2) {
                                [nearbyBuses setObject:one_route forKey:tripDescriptor.routeId];
                            }
                        } else {
                            [nearbyBuses setObject:one_route forKey:tripDescriptor.routeId];
                        }
                        
                    }
                }
            }
        
        [self.uITableView_comingBuses reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error (getTripUpdate) : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
}

- (void)UpdateViewByViewStatus {
    self.cSAnimationView_myLocation.hidden=NO;
    [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_myLocation];
    self.cSAnimationView_myLocation.type = CSAnimationTypeFadeIn;
    self.cSAnimationView_myLocation.duration = 0.0;
    self.cSAnimationView_myLocation.delay = 0.1;
    [self.cSAnimationView_myLocation startCanvasAnimation];
    
    switch (viewStatus) {
        case ViewStatus_mapview: {
            self.nSLayoutConstraint_cSAnimtionView_searchBar_height.constant = 59;
            self.nSLayoutConstraint_bar1_right_horizontal.constant = 8;
            
            
            self.uIButton_depart.hidden=YES;
            self.uIButton_arrive.hidden=YES;
            self.uITextField_topSearchBar2.hidden=YES;
            
            self.cSAnimationView_topSearchBar.hidden=NO;
            self.cSAnimationView_setStartEnd.hidden=YES;
            self.cSAnimationView_commingBuses.hidden=YES;
            
            // Animation
            [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_topSearchBar];
            
            self.cSAnimationView_topSearchBar.type = CSAnimationTypeSlideDown;
            self.cSAnimationView_topSearchBar.duration = 0.3;
            self.cSAnimationView_topSearchBar.delay = 0.0;
            [self.cSAnimationView_topSearchBar startCanvasAnimation];
            
            
            break;
        }
        case ViewStatus_mapview_locationDetermined: {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
//                NSMutableDictionary *nearbyBusStops = [appDelegate.dbManager getNearbyStops:1609 lat:center_coordinate.latitude lon:center_coordinate.longitude];
                
                // TEST
//                [self getTripUpdate:nearbyBusStops];
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                });
            });
            
            self.nSLayoutConstraint_cSAnimtionView_searchBar_height.constant = 59;
            self.nSLayoutConstraint_bar1_right_horizontal.constant = 8;
            
            self.nSLayoutConstraint_cSAnimtionView_comingBuses_height.constant=45;
            
            
            self.uIButton_depart.hidden=YES;
            self.uIButton_arrive.hidden=YES;
            self.uITextField_topSearchBar2.hidden=YES;
            
            self.cSAnimationView_topSearchBar.hidden=NO;
            self.cSAnimationView_setStartEnd.hidden=NO;
            self.cSAnimationView_commingBuses.hidden=YES;
            
            // Animation
            [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_topSearchBar];
            [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_setStartEnd];
            [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_commingBuses];
            
            self.cSAnimationView_setStartEnd.type = CSAnimationTypeFadeIn;
            self.cSAnimationView_setStartEnd.duration = 0.15;
            self.cSAnimationView_setStartEnd.delay = 0.0;
            [self.cSAnimationView_setStartEnd startCanvasAnimation];
            break;
        }
        case ViewStatus_planview: {
            self.nSLayoutConstraint_cSAnimtionView_comingBuses_height.constant=45;
            self.nSLayoutConstraint_cSAnimtionView_searchBar_height.constant = 97;
            self.nSLayoutConstraint_bar1_right_horizontal.constant = 92;
            
            
            self.uIButton_depart.hidden=NO;
            self.uIButton_arrive.hidden=NO;
            self.uITextField_topSearchBar2.hidden=NO;
            
            self.cSAnimationView_topSearchBar.hidden=NO;
            self.cSAnimationView_setStartEnd.hidden=YES;
            self.cSAnimationView_commingBuses.hidden=YES;
            
            // Animation
            [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_topSearchBar];
            
            self.cSAnimationView_topSearchBar.type = CSAnimationTypeSlideDown;
            self.cSAnimationView_topSearchBar.duration = 0.3;
            self.cSAnimationView_topSearchBar.delay = 0.0;
            [self.cSAnimationView_topSearchBar startCanvasAnimation];
            break;
        }
        case ViewStatus_planview_locationDetermined: {
            self.nSLayoutConstraint_cSAnimtionView_comingBuses_height.constant=45;
            self.nSLayoutConstraint_cSAnimtionView_searchBar_height.constant = 97;
            self.nSLayoutConstraint_bar1_right_horizontal.constant = 92;
            
            
            self.uIButton_depart.hidden=NO;
            self.uIButton_arrive.hidden=NO;
            self.uITextField_topSearchBar2.hidden=NO;
            
            self.cSAnimationView_topSearchBar.hidden=NO;
            self.cSAnimationView_setStartEnd.hidden=NO;
            self.cSAnimationView_commingBuses.hidden=NO;
            
            [self.uIButton_comming_buses setTitle:@"Plan Your Trip \U000021B5" forState:UIControlStateNormal];
            
            // Animation
            [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_topSearchBar];
            [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_setStartEnd];
            [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_commingBuses];
            
            self.cSAnimationView_setStartEnd.type = CSAnimationTypeFadeIn;
            self.cSAnimationView_setStartEnd.duration = 0.15;
            self.cSAnimationView_setStartEnd.delay = 0.0;
            [self.cSAnimationView_setStartEnd startCanvasAnimation];
            
            self.cSAnimationView_commingBuses.type = CSAnimationTypeFadeIn;
            self.cSAnimationView_commingBuses.duration = 0.15;
            self.cSAnimationView_commingBuses.delay = 0.0;
            [self.cSAnimationView_commingBuses startCanvasAnimation];
            
            
            break;
        }
        default:
            break;
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initMap {
    
    if(self.mapView)if(self.mapView) {
        [self.mapView clear];
        [self.mapView removeFromSuperview];
    }
    
    [self getCurrentLocation];
    
    geocoder = [[CLGeocoder alloc] init];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.locationManager.location.coordinate.latitude longitude:self.locationManager.location.coordinate.longitude zoom:12];
    self.mapView = [GMSMapView mapWithFrame:self.cSAnimationView_baseMap.bounds camera:camera];
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    self.mapView.indoorEnabled = NO;
    [self.cSAnimationView_baseMap addSubview:self.mapView];
    
    // Center Marker
    [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_centerMarker];
    
}

-(void)getCurrentLocation {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    NSLog(@"requestWhenInUseAuthorization");
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    if (firstTimeFlag) {
        [self.mapView animateToLocation:self.locationManager.location.coordinate];
        
        if (fakeLocationFlag) {
            CLLocationCoordinate2D center;
            center.latitude = fakeLat;
            center.longitude = fakeLon;
            
            [self.mapView animateToLocation:center];
        }
        
        firstTimeFlag = NO;
    }
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)didTapDepartTime:(id)sender {
    if (self.cSAnimationView_datePicker.hidden==NO) {
        self.cSAnimationView_datePicker.hidden = YES;
        self.uIButton_arrive.enabled = YES;
        self.uIButton_startFromHere.enabled = YES;
        self.uIButton_EndAtHere.enabled = YES;
        return;
    }
    self.cSAnimationView_datePicker.hidden=NO;
    [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_datePicker];
    //    nSTimeInterval_leaveAt = 0;
    self.uIButton_arrive.enabled = NO;
    self.uIButton_startFromHere.enabled = NO;
    self.uIButton_EndAtHere.enabled = NO;
    
}

- (IBAction)didTapArriveTime:(id)sender {
    
    if (self.cSAnimationView_datePicker.hidden==NO) {
        self.cSAnimationView_datePicker.hidden = YES;
        self.uIButton_depart.enabled = YES;
        self.uIButton_startFromHere.enabled = YES;
        self.uIButton_EndAtHere.enabled = YES;
        return;
    }
    self.cSAnimationView_datePicker.hidden=NO;
    [self.cSAnimationView_baseMap bringSubviewToFront:self.cSAnimationView_datePicker];
    //    nSTimeInterval_arriveBy = 0;
    self.uIButton_depart.enabled = NO;
    self.uIButton_startFromHere.enabled = NO;
    self.uIButton_EndAtHere.enabled = NO;
    
}

- (IBAction)didTapDatePicker_cancel:(id)sender {
    if (self.uIButton_arrive.enabled==NO) {
        nSTimeInterval_leaveAt=0;
        [self.uIButton_depart setBackgroundColor: [UIColor lightGrayColor]];
        [self.uIButton_depart setTitle:@"Depart Time" forState:UIControlStateNormal];
    } else {
        nSTimeInterval_arriveBy=0;
        [self.uIButton_arrive setBackgroundColor: [UIColor lightGrayColor]];
        [self.uIButton_arrive setTitle:@"Arrival Time" forState:UIControlStateNormal];
    }
    
    self.cSAnimationView_datePicker.hidden = YES;
    self.uIButton_depart.enabled = YES;
    self.uIButton_arrive.enabled = YES;
    self.uIButton_startFromHere.enabled = YES;
    self.uIButton_EndAtHere.enabled = YES;
    
    if (nSTimeInterval_leaveAt==0 && nSTimeInterval_arriveBy==0) {
        [self.uIButton_depart setBackgroundColor: DefaultGreen];
        [self.uIButton_depart setTitle:@"Depart Now" forState:UIControlStateNormal];
    }
    self.uIDatePicker_datePicker.date = [NSDate date];
}
- (IBAction)didTapDatePicker_done:(id)sender {
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM-dd HH:mm"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setLocale:locale];
    
    if (self.uIButton_arrive.enabled==NO) {
        nSTimeInterval_leaveAt = [self.uIDatePicker_datePicker.date timeIntervalSince1970];
        [self.uIButton_depart setBackgroundColor: DefaultGreen];
        [self.uIButton_depart setTitle:[df stringFromDate: [NSDate dateWithTimeIntervalSince1970:nSTimeInterval_leaveAt ]] forState:UIControlStateNormal];
    } else {
        nSTimeInterval_arriveBy = [self.uIDatePicker_datePicker.date timeIntervalSince1970];
        [self.uIButton_arrive setBackgroundColor: DefaultGreen];
        [self.uIButton_arrive setTitle:[df stringFromDate: [NSDate dateWithTimeIntervalSince1970:nSTimeInterval_arriveBy ]] forState:UIControlStateNormal];
    }
    
    self.cSAnimationView_datePicker.hidden = YES;
    self.uIButton_depart.enabled = YES;
    self.uIButton_arrive.enabled = YES;
    self.uIButton_startFromHere.enabled = YES;
    self.uIButton_EndAtHere.enabled = YES;
}

- (IBAction)didTapStartHere:(id)sender {
    NSLog(@"didTapStartHere");
    if (viewStatus==ViewStatus_mapview || viewStatus==ViewStatus_mapview_locationDetermined) {
        viewStatus=ViewStatus_planview;
        [self UpdateViewByViewStatus];
    }
    
    CLLocationCoordinate2D coor = center_coordinate;
    
    CLLocation *sectorLocation = [[CLLocation alloc] initWithLatitude:coor.latitude longitude:coor.longitude];
    
    
    [geocoder reverseGeocodeLocation:sectorLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error == nil && [placemarks count] > 0) {
            
            if (viewStatus==ViewStatus_planview) {
                viewStatus=ViewStatus_planview_locationDetermined;
                [self UpdateViewByViewStatus];
            }
            
            //
            self.frommarker.map = nil;
            self.frommarker = [[GMSMarker alloc] init];
            self.frommarker.title = @"";
            self.frommarker.icon = [UIImage imageNamed:@"start_marker@2x.png"];
            self.frommarker.position = CLLocationCoordinate2DMake(center_coordinate.latitude, center_coordinate.longitude);
            self.frommarker.map = self.mapView;
            
            if (!self.tomarker) {
                self.uITextField_topSearchBar2.text=@"[Current Location]";
                //
                self.tomarker.map = nil;
                self.tomarker = [[GMSMarker alloc] init];
                self.tomarker.title = @"";
                self.tomarker.icon = [UIImage imageNamed:@"end_marker@2x.png"];
                self.tomarker.position = CLLocationCoordinate2DMake(self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude);
                if (fakeLocationFlag)
                    self.tomarker.position = CLLocationCoordinate2DMake(fakeLat, fakeLon);
                self.tomarker.map = self.mapView;
                
                CLLocation *sectorLocation = [[CLLocation alloc] initWithLatitude:self.tomarker.position.latitude longitude:self.tomarker.position.longitude];
                
                [geocoder reverseGeocodeLocation:sectorLocation completionHandler:^(NSArray *placemarks, NSError *error) {
                    
                    if (error == nil && [placemarks count] > 0) {
                        
                        placemark = [placemarks lastObject];
                        if (placemark.subThoroughfare.length==0 || placemark.thoroughfare.length==0)
                            self.uITextField_topSearchBar2.text = [[NSString stringWithFormat:@"%@, %@ %@",
                                                                    placemark.locality, placemark.administrativeArea,
                                                                    placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
                        else
                            self.uITextField_topSearchBar2.text = [[NSString stringWithFormat:@"%@ %@, %@, %@ %@",
                                                               placemark.subThoroughfare, placemark.thoroughfare,
                                                               placemark.locality, placemark.administrativeArea,
                                                               placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
                    } else {
                        NSLog(@"%@", error.debugDescription);
                    }
                } ];

            }
            
            self.cSAnimationView_centerMarker.alpha=0;
            
            [self drawRouteBetweenFromAndTo];
            
            placemark = [placemarks lastObject];
            if (placemark.subThoroughfare.length==0 || placemark.thoroughfare.length==0)
                self.uITextField_topSearchBar.text = [[NSString stringWithFormat:@"%@, %@ %@",
                                                        placemark.locality, placemark.administrativeArea,
                                                        placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
            else
                self.uITextField_topSearchBar.text = [[NSString stringWithFormat:@"%@ %@, %@, %@ %@",
                                                   placemark.subThoroughfare, placemark.thoroughfare,
                                                   placemark.locality, placemark.administrativeArea,
                                                   placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
            
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
}

- (IBAction)didTapEndHere:(id)sender {
    NSLog(@"didTapEndHere");
    
    if (viewStatus==ViewStatus_mapview || viewStatus==ViewStatus_mapview_locationDetermined) {
        viewStatus=ViewStatus_planview;
        [self UpdateViewByViewStatus];
    }
    
    CLLocationCoordinate2D coor = center_coordinate;
    
    CLLocation *sectorLocation = [[CLLocation alloc] initWithLatitude:coor.latitude longitude:coor.longitude];
    
    
    [geocoder reverseGeocodeLocation:sectorLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error == nil && [placemarks count] > 0) {
            
            if (viewStatus==ViewStatus_planview) {
                viewStatus=ViewStatus_planview_locationDetermined;
                [self UpdateViewByViewStatus];
            }
            
            if (!self.frommarker) {
//                self.uITextField_topSearchBar.text=@"[Current Location]";
                
                //
                self.frommarker.map = nil;
                self.frommarker = [[GMSMarker alloc] init];
                self.frommarker.title = @"";
                self.frommarker.icon = [UIImage imageNamed:@"start_marker@2x.png"];
                self.frommarker.position = CLLocationCoordinate2DMake(self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude);
                if (fakeLocationFlag)
                    self.frommarker.position = CLLocationCoordinate2DMake(fakeLat, fakeLon);
                self.frommarker.map = self.mapView;
                
                CLLocation *sectorLocation = [[CLLocation alloc] initWithLatitude:self.frommarker.position.latitude longitude:self.frommarker.position.longitude];
                
                [geocoder reverseGeocodeLocation:sectorLocation completionHandler:^(NSArray *placemarks, NSError *error) {
                    
                    if (error == nil && [placemarks count] > 0) {
                        
                        placemark = [placemarks lastObject];
                        if (placemark.subThoroughfare.length==0 || placemark.thoroughfare.length==0)
                            self.uITextField_topSearchBar.text = [[NSString stringWithFormat:@"%@, %@ %@",
                                                                    placemark.locality, placemark.administrativeArea,
                                                                    placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
                        else
                            self.uITextField_topSearchBar.text = [[NSString stringWithFormat:@"%@ %@, %@, %@ %@",
                                                               placemark.subThoroughfare, placemark.thoroughfare,
                                                               placemark.locality, placemark.administrativeArea,
                                                               placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
                    } else {
                        NSLog(@"%@", error.debugDescription);
                    }
                } ];

            }
            
            
            //
            self.tomarker.map = nil;
            self.tomarker = [[GMSMarker alloc] init];
            self.tomarker.title = @"";
            self.tomarker.icon = [UIImage imageNamed:@"end_marker@2x.png"];
            self.tomarker.position = CLLocationCoordinate2DMake(center_coordinate.latitude, center_coordinate.longitude);
            self.tomarker.map = self.mapView;
            
            self.cSAnimationView_centerMarker.alpha=0;
            
            [self drawRouteBetweenFromAndTo];
            
            [self.mapView setSelectedMarker:nil];
            
            placemark = [placemarks lastObject];
            if (placemark.subThoroughfare.length==0 || placemark.thoroughfare.length==0)
                self.uITextField_topSearchBar2.text = [[NSString stringWithFormat:@"%@, %@ %@",
                                                        placemark.locality, placemark.administrativeArea,
                                                        placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
            else
                self.uITextField_topSearchBar2.text = [[NSString stringWithFormat:@"%@ %@, %@, %@ %@",
                                                    placemark.subThoroughfare, placemark.thoroughfare,
                                                    placemark.locality, placemark.administrativeArea,
                                                    placemark.postalCode] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
            
            
        } else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
    
}

-(void)drawRouteBetweenFromAndTo {
    if (self.frommarker && self.tomarker) {
        GMSMutablePath *path = [GMSMutablePath path];
        [path addCoordinate:CLLocationCoordinate2DMake(self.frommarker.position.latitude, self.frommarker.position.longitude)];
        [path addCoordinate:CLLocationCoordinate2DMake(self.tomarker.position.latitude, self.tomarker.position.longitude)];
        
        polyline_from_to.map=nil;
        
        polyline_from_to = [GMSPolyline polylineWithPath:path];
        polyline_from_to.strokeWidth = 5.f;
        polyline_from_to.geodesic = YES;
        polyline_from_to.map = self.mapView;
        polyline_from_to.strokeColor = [UIColor colorWithRed:119/255.0 green:201/255.0 blue:177/255.0 alpha:1];
    }
}

- (Boolean)checkIfHistoryExist: (NSString *) str {
    for (SearchHistory *searchHistory in array_searchHistory) {
        if ([searchHistory.address isEqualToString:str])
            return YES;
    }
    return NO;
}

- (Boolean)checkIfIsInNashvilleWithLatitude: (float) latitude andLongitude: (float) longitude {
//    if (latitude<36.621473 && longitude> -87.545533 && latitude> && longitude)
    return YES;
}

- (IBAction)didTap_coming_buses:(id)sender {
    if (viewStatus==ViewStatus_mapview_locationDetermined) {
        if (self.nSLayoutConstraint_cSAnimtionView_comingBuses_height.constant>45) {
            self.nSLayoutConstraint_cSAnimtionView_comingBuses_height.constant=45;
            [self.uIButton_comming_buses setTitle:@"Nearby Buses \U00002191" forState:UIControlStateNormal];
        } else {
            self.nSLayoutConstraint_cSAnimtionView_comingBuses_height.constant=300;
            [self.uIButton_comming_buses setTitle:@"Nearby Buses \U00002193" forState:UIControlStateNormal];
        }
        
    } else if (viewStatus==ViewStatus_planview_locationDetermined) {
        if ([statusView isDescendantOfView:self.view])
            return;
        
        //
        if (![self checkIfHistoryExist:self.uITextField_topSearchBar.text]) {
            SearchHistory *searchHistory = [CoreDataHelper insertManagedObjectOfClass:[SearchHistory class] inManagedObjectContext:objectContext ];
            searchHistory.address = self.uITextField_topSearchBar.text;
            searchHistory.timestamp = [NSNumber numberWithInteger: [[NSDate date] timeIntervalSince1970] ];
            [CoreDataHelper saveManagedObjectContext:objectContext];
        }
        if (![self checkIfHistoryExist:self.uITextField_topSearchBar2.text]) {
            SearchHistory *searchHistory2 = [CoreDataHelper insertManagedObjectOfClass:[SearchHistory class] inManagedObjectContext:objectContext ];
            searchHistory2.address = self.uITextField_topSearchBar2.text;
            searchHistory2.timestamp = [NSNumber numberWithInteger: [[NSDate date] timeIntervalSince1970] ];
            [CoreDataHelper saveManagedObjectContext:objectContext];
        }
        
        statusView = [[StatusView alloc] initWithText:@"Planning routes..." delayToHide:0 iconIndex:0];
        [self.view addSubview:statusView];
        
        //
        param = [[NSMutableDictionary alloc] init];
        [param setObject:[NSString stringWithFormat:@"%f", self.frommarker.position.latitude ] forKey:@"departureLat"];
        [param setObject:[NSString stringWithFormat:@"%f", self.frommarker.position.longitude ] forKey:@"departureLng"];
        [param setObject:[NSString stringWithFormat:@"%f", self.tomarker.position.latitude ] forKey:@"arrivalLat"];
        [param setObject:[NSString stringWithFormat:@"%f", self.tomarker.position.longitude ] forKey:@"arrivalLng"];
        
        if (nSTimeInterval_leaveAt==0 && nSTimeInterval_arriveBy==0) {
            self.uIDatePicker_datePicker.date = [NSDate date];
            nSTimeInterval_leaveAt = [self.uIDatePicker_datePicker.date timeIntervalSince1970];
        }
        if ([self.uIButton_depart.currentTitle isEqualToString:@"Depart Now"]) {
            self.uIDatePicker_datePicker.date = [NSDate date];
            nSTimeInterval_leaveAt = [self.uIDatePicker_datePicker.date timeIntervalSince1970];
        }
            
//        NSLog(@"TMP:::%@, %f", self.uIButton_depart.currentTitle, nSTimeInterval_leaveAt);
        [param setObject:[NSString stringWithFormat:@"%.0f", nSTimeInterval_leaveAt] forKey:@"departureTime"];
        [param setObject:[NSString stringWithFormat:@"%.0f", nSTimeInterval_arriveBy] forKey:@"arrivalTime"];
        
        [param setObject:self.uITextField_topSearchBar.text forKey:@"departureAddress"];
        [param setObject:self.uITextField_topSearchBar2.text forKey:@"arrivalAddress"];
        
        // Data Collection
        NSMutableDictionary *startLocation = [[NSMutableDictionary alloc] initWithCapacity:2];
        [startLocation setValue:[param objectForKey:@"departureLat"] forKey:@"lattitude"];
        [startLocation setValue:[param objectForKey:@"departureLng"] forKey:@"longitude"];
        NSMutableDictionary *endLocation = [[NSMutableDictionary alloc] initWithCapacity:2];
        [endLocation setValue:[param objectForKey:@"arrivalLat"] forKey:@"lattitude"];
        [endLocation setValue:[param objectForKey:@"arrivalLng"] forKey:@"longitude"];
        
        NSMutableDictionary *searchData = [[NSMutableDictionary alloc] initWithCapacity:6];
        [searchData setValue:[[NSUUID UUID] UUIDString] forKey:@"deviceUUID"];
        [searchData setValue:[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]] forKey:@"searchTime"];
        [searchData setValue:[param objectForKey:@"departureTime"] forKey:@"departureTime"];
        [searchData setValue:[param objectForKey:@"arrivalTime"] forKey:@"arrivalTime"];
        [searchData setValue:startLocation forKey:@"startLocation"];
        [searchData setValue:endLocation forKey:@"endLocation"];
        
        [self dataCollection:searchData];
        
        
    }
}

-(void)dataCollection:(NSMutableDictionary *)map_data {

    NSString *submitURL = [@"https://c3stem.isis.vanderbilt.edu" stringByAppendingString:@"/saveSearch"];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:submitURL]];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    //    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"thub_demo" forHTTPHeaderField:@"Authorization"];
    [manager.requestSerializer setValue: @"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"application/json" , nil];
    
    [manager POST:submitURL parameters:map_data success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        nSTimer_timeout = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideStatusView) userInfo:nil repeats:NO];
        
        NSMutableDictionary *responseJSON = [[NSMutableDictionary alloc] initWithDictionary:(NSMutableDictionary *)responseObject];
        NSString *searchID = [[responseJSON objectForKey:@"response"] objectForKey:@"search_id"];
        
        [param setValue:searchID forKey:@"search_id"];
        
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:param
                                                           options:kNilOptions error:nil];
        NSString *jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSString *function = [NSString stringWithFormat:@"start('%@')", jsonDataStr];
//        NSLog(@"TEST::: function111: %@", function);
        NSString *result = [webView stringByEvaluatingJavaScriptFromString:function];
        result = @"";
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"dataCollection - failure: %@",error);
        //
        nSTimer_timeout = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideStatusView) userInfo:nil repeats:NO];
        
        [param setValue:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]] forKey:@"search_id"];
        
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:param
                                                           options:kNilOptions error:nil];
        NSString *jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSString *function = [NSString stringWithFormat:@"start('%@')", jsonDataStr];
        NSString *result = [webView stringByEvaluatingJavaScriptFromString:function];
        result = @"";
    }];
 
}

- (void)hideStatusView {
    if ([statusView isDescendantOfView:self.view])
        [statusView removeFromSuperview];
    statusView = [[StatusView alloc] initWithText:@"No route is found." delayToHide:1.4 iconIndex:1];
    [self.view addSubview:statusView];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    
    NSString* urlString = [NSString stringWithFormat:@"%@",[[request URL] absoluteString]];
    NSLog(@"TMP:::urlString:::%@", urlString);
    
    if ([urlString hasPrefix:@"result:"]) {
        [statusView removeFromSuperview];
        [nSTimer_timeout invalidate];
        nSTimer_timeout=nil;
        
        urlString = [[self decodeFromPercentEscapeString: urlString] substringFromIndex: 19];
        
        NSRange r;
        while ((r = [urlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
            urlString = [urlString stringByReplacingCharactersInRange:r withString:@""];
        
        NSMutableDictionary *route_dic = [NSJSONSerialization JSONObjectWithData:[urlString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        
//                NSLog(@"route_dic %@", route_dic);
        if (route_dic==nil) {
            if ([statusView isDescendantOfView:self.view])
                [statusView removeFromSuperview];
            statusView = [[StatusView alloc] initWithText:@"No route is found." delayToHide:1.4 iconIndex:1];
            [self.view addSubview:statusView];
            
            return NO;
        }
        
        SuggestedRoutesViewController * suggestedRoutesViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"suggestedRoutesViewController"];
        suggestedRoutesViewController.route_dic = route_dic;
        suggestedRoutesViewController.scheduled_route_param = param;
        suggestedRoutesViewController.address_from = self.uITextField_topSearchBar.text;
        suggestedRoutesViewController.address_to = self.uITextField_topSearchBar2.text;
        
        [self presentViewController:suggestedRoutesViewController animated:NO completion:nil];
        
        return NO;
    } else if ([urlString hasPrefix:@"address:"]) {
        urlString = [[self decodeFromPercentEscapeString: urlString] substringFromIndex: 20];
        
        NSRange r;
        while ((r = [urlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
            urlString = [urlString stringByReplacingCharactersInRange:r withString:@""];
        
        NSMutableDictionary *map_address = [NSJSONSerialization JSONObjectWithData:[urlString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        
        if ([[map_address objectForKey:@"tag"] isEqualToString:@"1"]) {
            self.uITextField_topSearchBar.text = [map_address objectForKey:@"formatted_address"];
            if (![self checkIfHistoryExist: self.uITextField_topSearchBar.text]) {
                // Save text field text
                SearchHistory *searchHistory = [CoreDataHelper insertManagedObjectOfClass:[SearchHistory class] inManagedObjectContext:objectContext ];
                searchHistory.address = self.uITextField_topSearchBar.text;
                searchHistory.timestamp = [NSNumber numberWithInteger: [[NSDate date] timeIntervalSince1970] ];
                [CoreDataHelper saveManagedObjectContext:objectContext];
            }
        } else if ([[map_address objectForKey:@"tag"] isEqualToString:@"2"]) {
            self.uITextField_topSearchBar2.text = [map_address objectForKey:@"formatted_address"];
            if (![self checkIfHistoryExist: self.uITextField_topSearchBar2.text]) {
                // Save text field text
                SearchHistory *searchHistory = [CoreDataHelper insertManagedObjectOfClass:[SearchHistory class] inManagedObjectContext:objectContext ];
                searchHistory.address = self.uITextField_topSearchBar2.text;
                searchHistory.timestamp = [NSNumber numberWithInteger: [[NSDate date] timeIntervalSince1970] ];
                [CoreDataHelper saveManagedObjectContext:objectContext];
            }
        }
        return YES;
    } else if ([urlString hasPrefix:@"autocomplete:"]) {
        urlString = [[self decodeFromPercentEscapeString: urlString] substringFromIndex: 25];
        
        NSRange r;
        while ((r = [urlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
            urlString = [urlString stringByReplacingCharactersInRange:r withString:@""];
        
        NSMutableArray *map_addresses = [NSJSONSerialization JSONObjectWithData:[urlString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        
        NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:map_addresses.count];
        if (map_addresses.count>0) {
            for (NSString *address in map_addresses) {
                NSEntityDescription *entity = [NSEntityDescription entityForName:@"SearchHistory" inManagedObjectContext:objectContext];
                SearchHistory *searchHistory = (SearchHistory *)[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
                searchHistory.address = [address stringByReplacingOccurrencesOfString:@", United States"
                                                                               withString:@""];
                searchHistory.timestamp = [NSNumber numberWithInteger: 0 ];
                [tmpArray addObject:searchHistory];
            }
            array_searchHistory = [tmpArray copy];
            self.uILabel_searchHistory_title.text = @"  ADDRESS SUGGESTIONS";
            self.uILabel_searchHistory_title.backgroundColor = DefaultOrange;
        } else {
            [self loadSearchHistory];
        }
        [self.uITableView_searchHistory reloadData];
        return YES;
    } else
        return YES;
}

// Decode a percent escape encoded string.
- (NSString*) decodeFromPercentEscapeString:(NSString *) string {
    return (__bridge NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                         (__bridge CFStringRef) string,
                                                                                         CFSTR(""),
                                                                                         kCFStringEncodingUTF8);
}

- (IBAction)didTapMyLocation:(id)sender {
    [self.mapView animateToLocation:self.locationManager.location.coordinate];
    if (fakeLocationFlag) {
        CLLocationCoordinate2D center;
        center.latitude = fakeLat;
        center.longitude = fakeLon;
        
        [self.mapView animateToLocation:center];
    }
}
- (IBAction)didTapHideSearchHistoryView:(id)sender {
    self.cSAV_searchHistory.hidden = YES;
}
@end
