//
//  SuggestedRoutesViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 5/11/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

/*
 This is the suggested route view controller
 This view provides the suggested transit routes to users after they tap the "Plan Your Trip" button in trip planner.
 */

#import "SuggestedRoutesViewController.h"
#import "RouteTableViewCell.h"
#import "ColorConstants.h"
#import "JSONParser.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import "RouteDetailsViewController.h"
#import "AFNetworking.h"
#import "ScheduledTrip.h"
#import "RealtimeViewController.h"
#import <ProtocolBuffers/ProtocolBuffers.h>
#import "GtfsRealtime.pb.h"

@interface SuggestedRoutesViewController () {
    JSONParser *jsonParser;
    AppDelegate *appDelegate;
    UIWebView *webView;
    float gasSaving;
    NSString *last_UUID;
    
    NSManagedObjectContext* objectContext;
    NSMutableDictionary *nSMDictionary_tripID_stops;
    NSMutableDictionary *nSMDictionary_routeID_tripID;
    
    NSMutableDictionary *map_cellIndex_stepInfoToDisplay_dic;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nSLayoutCOnstraint_alternativesViewHeight;

@end

@implementation SuggestedRoutesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    map_cellIndex_stepInfoToDisplay_dic = [[NSMutableDictionary alloc] init];
    
    objectContext = [CoreDataHelper managedObjectContext];
    
    gasSaving = -1;
    
    [self initWebview];
    self.nSLayoutCOnstraint_alternativesViewHeight.constant = 0;
    // Do any additional setup after loading the view.
    
    // AppDelegate
    appDelegate = ((AppDelegate*)[[UIApplication sharedApplication]delegate]);
    
    jsonParser = [[JSONParser alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self getTripUpdates];
    
    [self updateFromToAddressesFromLatLng];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self initAlternativesView];
    });
}

-(void)getTripUpdates {
    NSURL *URL=[NSURL URLWithString: tripUpdatesURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (!responseObject) return;
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
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
                
                NSMutableArray *tripArray = [nSMDictionary_routeID_tripID objectForKey:routeId];
                if (!tripArray) {
                    tripArray = [[NSMutableArray alloc] initWithCapacity:5];
                }
                [tripArray addObject:tripId];
                [nSMDictionary_routeID_tripID setObject:tripArray forKey:routeId];
                
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
                
                // Save to map
                [nSMDictionary_tripID_stops setObject:nSMDictionary_trip forKey:tripId];
            }
        }
        [self.uitableview_routes reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initWebview {
    webView = [[UIWebView alloc] init];
    webView.delegate = self;
    //    [webView loadHTMLString:@"<script src=\"calc.js\"></script>" baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GoogleMap_car" ofType:@"html"]isDirectory:NO]]];
}

- (void)initAlternativesView {
    
    
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:self.scheduled_route_param
                                                       options:kNilOptions error:nil];
    NSString *jsonDataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *function = [NSString stringWithFormat:@"start('%@')", jsonDataStr];
    [webView stringByEvaluatingJavaScriptFromString:function];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    //    NSLog(@"TEST::: shouldStartLoadWithRequest");
    
    NSString* urlString = [NSString stringWithFormat:@"%@",[[request URL] absoluteString]];
    
    //    NSLog(@"TEST::: urlString: %@",urlString);
    if ([urlString hasPrefix:@"result:"]) {
        
        self.nSLayoutCOnstraint_alternativesViewHeight.constant = 85;
        
        urlString = [[self decodeFromPercentEscapeString: urlString] substringFromIndex: 19];
        
        NSRange r;
        while ((r = [urlString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
            urlString = [urlString stringByReplacingCharactersInRange:r withString:@""];
        
        NSMutableDictionary *route_dic = [NSJSONSerialization JSONObjectWithData:[urlString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        
        //        NSLog(@"route_dic %@", route_dic);
        
        NSMutableDictionary *leg_array = [(NSMutableArray *)[[[route_dic objectForKey:@"routes"] objectAtIndex:0] objectForKey:@"legs"] objectAtIndex:0];
        
        float transit_distance_mile = [[[leg_array objectForKey:@"distance"] objectForKey:@"value"] floatValue]/1609;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *gasPrice = [defaults valueForKey:@"gasPrice"];
        
        self.uILabel_car_label1.text = [NSString stringWithFormat:@"Total: %@  Distance: %@", [[leg_array objectForKey:@"duration"] objectForKey:@"text"], [[leg_array objectForKey:@"distance"] objectForKey:@"text"]];
        self.uILabel_car_label2.text = [NSString stringWithFormat:@"Gas Cost: $%.1f  Parking Cost: Unavailable", [gasPrice floatValue]/24*transit_distance_mile];
        gasSaving = [gasPrice floatValue]/24*transit_distance_mile;
        [self.uitableview_routes reloadData];
        
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //    return [route_array count];
    return [[self.route_dic objectForKey:@"routes"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RouteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RouteCell"];
    
    //    cell.lbl_route_details.text = @"\U0001F6B6 > \U0001F68C SL5 > \U0001F6B6";
    
    NSMutableDictionary *route_dic_local = [((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row];
    
    //    NSLog(@"212route_dic_local: %@", route_dic_local);
    
    NSMutableDictionary *result = [jsonParser getRouteDetails:route_dic_local];
    
    //    if ([[NSString stringWithFormat:@"%@",[result objectForKey:@"start_time"]] isEqualToString:@"(null)"])  {
    //        [cell.subviews setValue:@YES forKeyPath:@"hidden"];
    //    }
    
    //    NSLog(@"212result: %@", result);
    cell.lbl_start_time.text = [result objectForKey:@"start_time"];
    
    cell.lbl_end_time.text = [result objectForKey:@"end_time"];
    
    cell.lbl_month.text = [result objectForKey:@"date"];
    
    //    NSLog(@"t926: %@, %@", [result objectForKey:@"date"], cell.lbl_month.text);
    
    cell.lbl_route_details.text = [result objectForKey:@"route_details"];
    cell.lbl_route_details.text = @"";
    NSMutableArray *route_details_array = [result objectForKey:@"route_details_array"];
    float length_route_details = 0.0;
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(8, 29, screenBound.size.width-116,20)];
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
        aLabel.textColor = [UIColor darkGrayColor];
        if ([detail rangeOfString:@"UNICODE"].location != NSNotFound) {
            aLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        }
        length_route_details +=aLabel.frame.size.width;
        [aView addSubview:aLabel];
    }
    
    [cell addSubview:aView];
    
    //    cell.uILabel_expected_delay.text = [NSString stringWithFormat: @"Typical Delay: %dmin", (rand()%20+1)];
    cell.uILabel_expected_delay.text = [NSString stringWithFormat: @"Typical Delay: -"];
    if ((int)[result objectForKey:@"index_firstTransitStep"]!=-1) {
        // Check if today?
        NSDate *tripDate = [result objectForKey:@"date_start_time"];
        if (tripDate) {
            if ([[NSCalendar currentCalendar] isDateInToday:tripDate]) {
                NSDictionary *stepInfoToDisplay_dic = [map_cellIndex_stepInfoToDisplay_dic objectForKey:[NSString stringWithFormat:@"%ld", (long)indexPath.row]];
                if (!stepInfoToDisplay_dic) {
                    stepInfoToDisplay_dic = [appDelegate.dbManager getTripInformationFromRouteDictionary: [((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row] step_index:[[result objectForKey:@"index_firstTransitStep"] intValue]];
//                    NSLog(@"TMP:::123:::%d,%@", [[result objectForKey:@"index_firstTransitStep"] intValue], stepInfoToDisplay_dic);
                    NSString *trip_id = [NSString stringWithFormat:@"%@", [stepInfoToDisplay_dic objectForKey:@"trip_id"]];
                    int start_stop_sequence = [[stepInfoToDisplay_dic objectForKey:@"start_stop_sequence"] intValue];
                    
                    NSMutableDictionary *map_trip_id = [nSMDictionary_tripID_stops objectForKey:trip_id];
//                    NSLog(@"TMP::::::%@, %d, %@", trip_id, start_stop_sequence, map_trip_id);
                    if (map_trip_id) {
                        NSMutableArray *array_stops = [map_trip_id objectForKey:@"stops"];
                        if (array_stops) {
                            for (NSMutableDictionary *tripUpdateStopTimeUpdateDic in array_stops) {
                                if ([[tripUpdateStopTimeUpdateDic objectForKey:@"stopSequence"] intValue]==start_stop_sequence) {
                                    cell.uILabel_expected_delay.text = [NSString stringWithFormat: @"Current Delay: %d min", [[tripUpdateStopTimeUpdateDic objectForKey:@"delay"] intValue]/60];
                                }
                            }
                        }
                    }
                    
                    
                } else
                    cell.uILabel_expected_delay.text = [NSString stringWithFormat: @"Current Delay: -"];
            }
        }
    }
    
    cell.lbl_route_times.text = [result objectForKey:@"route_times"];
    
    cell.lbl_mtaPoints.text = [result objectForKey:@"CaloriesToBurn"];
    //    NSLog(@"TEST::: gasSaving::: %f", gasSaving);
    
    [cell.uibtn_prefer addTarget:self action:@selector(addToCalendar:) forControlEvents:UIControlEventTouchUpInside];
    [cell.uIButton_goNow addTarget:self action:@selector(goNow:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (Boolean)checkIfIsInNashvilleWithLatitude: (float) latitude andLongitude: (float) longitude {
    if (latitude<36.621473 && longitude> -87.545533 && latitude> 35.758253 && longitude<-86.201456)
    return YES;
    else
    return NO;
}

- (void)goNow:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.uitableview_routes];
    NSIndexPath *indexPath = [self.uitableview_routes indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil) {
        
        if (![self checkIfIsInNashvilleWithLatitude: [[self.scheduled_route_param objectForKey:@"departureLat"] floatValue] andLongitude: [[self.scheduled_route_param objectForKey:@"departureLng"] floatValue]] || ![self checkIfIsInNashvilleWithLatitude: [[self.scheduled_route_param objectForKey:@"arrivalLat"] floatValue] andLongitude: [[self.scheduled_route_param objectForKey:@"arrivalLng"] floatValue]]) {
            UIAlertController * alert=   [UIAlertController
                                          alertControllerWithTitle:@""
                                          message:@"The route is not supported yet."
                                          preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Got it"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action)
                                        {
                                            //Handel your yes please button action here
                                            [alert dismissViewControllerAnimated:YES completion:nil];
                                            
                                        }];
            
            [alert addAction:yesButton];
            
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        
        [self addToCalendar:sender];
        
        RealtimeViewController * realtimeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RealtimeViewController"];
        realtimeViewController.calendar_searchID = [self.scheduled_route_param objectForKey:@"search_id"];
        realtimeViewController.calendar_route_dic_from_database = [((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row];
        if (last_UUID)
            realtimeViewController.calendar_ScheduledTrip_uuid = last_UUID;
        
        UITabBarController *presentingViewController = (UITabBarController *)self.presentingViewController;
        [presentingViewController presentViewController:realtimeViewController animated:YES completion:nil];
    }
}

- (void)addToCalendar:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.uitableview_routes];
    NSIndexPath *indexPath = [self.uitableview_routes indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil)
    {
        
        NSMutableDictionary *route_dic_local = [((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row];
        //
        //        NSMutableDictionary *result = [jsonParser getRouteDetails:route_dic_local];
        
        // Core Data
        NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"departureLat==%@ AND departureLng==%@ AND arrivalLat==%@ AND arrivalLng==%@ AND departureTime==%@ AND arrivalTime==%@", [self.scheduled_route_param objectForKey:@"departureLat"], [self.scheduled_route_param objectForKey:@"departureLng"], [self.scheduled_route_param objectForKey:@"arrivalLat"], [self.scheduled_route_param objectForKey:@"arrivalLng"], [NSNumber numberWithInteger: [[self.scheduled_route_param objectForKey:@"departureTime"] integerValue]], [NSNumber numberWithInteger: [[self.scheduled_route_param objectForKey:@"arrivalTime"] integerValue]] ] inManagedObjectContext:objectContext];
        
        for (ScheduledTrip *old_scheduledTrip in items) {
            [objectContext deleteObject:old_scheduledTrip];
        }
        
        [CoreDataHelper saveManagedObjectContext:objectContext];
        //        [self deletePreviousRecord];
        
        NSString *label_from = self.uILabel_departTime.text;
        if ([label_from rangeOfString:@","].location!=NSNotFound)
            label_from = [label_from substringToIndex: [label_from rangeOfString:@","].location];
        NSString *label_to = self.uILabel_arrivalTime.text;
        if ([label_to rangeOfString:@","].location!=NSNotFound)
            label_to = [label_to substringToIndex: [label_to rangeOfString:@","].location];
        NSString *route_dictionary = [[NSString stringWithFormat:@"%@", [((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row] ]  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        ScheduledTrip *scheduledTrip = [CoreDataHelper insertManagedObjectOfClass:[ScheduledTrip class] inManagedObjectContext:objectContext ];
        scheduledTrip.arrivalLat = [self.scheduled_route_param objectForKey:@"arrivalLat"];
        scheduledTrip.arrivalLng = [self.scheduled_route_param objectForKey:@"arrivalLng"];
        scheduledTrip.arrivalText = label_to;
        scheduledTrip.arrivalTime = [NSNumber numberWithInteger: [[self.scheduled_route_param objectForKey:@"arrivalTime"] integerValue]];
        scheduledTrip.departureLat = [self.scheduled_route_param objectForKey:@"departureLat"];
        scheduledTrip.departureLng = [self.scheduled_route_param objectForKey:@"departureLng"];
        scheduledTrip.departureText = label_from;
        scheduledTrip.departureTime = [NSNumber numberWithInteger: [[self.scheduled_route_param objectForKey:@"departureTime"] integerValue]];
        scheduledTrip.fromAddress = [[self.uILabel_from.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
        scheduledTrip.toAddress = [[self.uILabel_to.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
        scheduledTrip.googleTripDic = route_dictionary;
        scheduledTrip.isRecurring = 0;
        scheduledTrip.searchID = [self.scheduled_route_param objectForKey:@"search_id"];
        scheduledTrip.checkpoint = [NSNumber numberWithInt:-1];
        scheduledTrip.uuid = [[NSUUID UUID] UUIDString];
        last_UUID = scheduledTrip.uuid;
        
        //
        if (scheduledTrip.googleTripDic && scheduledTrip.googleTripDic.length>0) {
            NSString *tmp = [scheduledTrip.googleTripDic stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *tripDic = [NSPropertyListSerialization
                                            propertyListWithData:[tmp dataUsingEncoding:NSUTF8StringEncoding]
                                            options:kNilOptions
                                            format:NULL
                                            error:NULL];
            NSMutableDictionary *parsedDic = [jsonParser getRouteDetails:tripDic];
            scheduledTrip.scheduledDepartureTime = [NSNumber numberWithInteger: [[parsedDic objectForKey:@"date_start_time"] timeIntervalSince1970]];
        }
        
        [CoreDataHelper saveManagedObjectContext:objectContext];
        
        appDelegate.calendar_added_schedule_timestamp = [[self.scheduled_route_param objectForKey:@"departureTime"] integerValue];
        
        // Data Collection
        NSMutableDictionary *result2 = [jsonParser getRouteDetailsForDataCollection:route_dic_local];
        
        NSMutableDictionary *searchData = [[NSMutableDictionary alloc] initWithCapacity:6];
        [searchData setValue:[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]] forKey:@"planTime"];
        [searchData setValue:[self.scheduled_route_param objectForKey:@"search_id"] forKey:@"searchID"];
        
        [searchData setObject:[result2 objectForKey:@"resultForSaveItinerary"] forKey:@"tripMarkers"];
        [searchData setObject:[result2 objectForKey:@"incentives"] forKey:@"incentives"];
        
        [self dataCollection:searchData];
        
        NSMutableDictionary *result3 = [jsonParser getRouteDetailsForDataCollection_actualTrip:route_dic_local];
        
        NSMutableDictionary *searchData2 = [[NSMutableDictionary alloc] initWithCapacity:6];
        [searchData2 setValue:[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970]] forKey:@"endTime"];
        [searchData2 setValue:[self.scheduled_route_param objectForKey:@"search_id"] forKey:@"searchID"];
        
        [searchData2 setObject:[result3 objectForKey:@"resultForSaveItinerary"] forKey:@"tripMarkers"];
        
        [self dataCollection_actualTrip:searchData2];
        
        
        UITabBarController *presentingViewController = (UITabBarController *)self.presentingViewController;
        presentingViewController.selectedIndex = 1;
        
        //        NSLog(@"parentViewController: %@", [self.presentingViewController class]);
        [self updateLocalNotifications];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)dataCollection:(NSMutableDictionary *)map_data {
    NSString *submitURL = saveItineraryURL;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:submitURL]];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    //    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"thub_demo" forHTTPHeaderField:@"Authorization"];
    [manager.requestSerializer setValue: @"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"application/json" , nil];
    
    NSLog(@"dataCollection: %@",map_data);
    
    [manager POST:submitURL parameters:map_data success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSMutableDictionary *responseJSON = [[NSMutableDictionary alloc] initWithDictionary:(NSMutableDictionary *)responseObject];
        
        NSLog(@"dataCollectionYES: %@",[responseJSON objectForKey:@"response"]);
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"dataCollection - failure: %@",error);
    }];
    
}

-(void)dataCollection_actualTrip:(NSMutableDictionary *)map_data {
    NSString *submitURL = saveActualTripURL;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:submitURL]];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    //    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"thub_demo" forHTTPHeaderField:@"Authorization"];
    [manager.requestSerializer setValue: @"application/json" forHTTPHeaderField:@"Content-Type"];
    
    //    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"application/json" , nil];
    
    NSLog(@"dataCollection: %@",map_data);
    
    [manager POST:submitURL parameters:map_data success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"dataCollection: %@",responseObject);
        
        NSMutableDictionary *responseJSON = [[NSMutableDictionary alloc] initWithDictionary:(NSMutableDictionary *)responseObject];
        
        NSLog(@"dataCollectionYES: %@",[responseJSON objectForKey:@"response"]);
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"dataCollection - failure: %@",error);
    }];
    
}

-(void)updateLocalNotifications {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDate *now = [NSDate date];
    
    NSInteger nowTimestamp = (NSInteger)[now timeIntervalSince1970];
    
    // Core Data
    NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"scheduledDepartureTime>%@ ", [NSNumber numberWithInteger:nowTimestamp] ] inManagedObjectContext:objectContext];
    
    NSLog(@"TMP:::items:::%lu:::%ld", (unsigned long)[items count], (long)nowTimestamp);
    if ([items count]>0) {
        UIApplication* app = [UIApplication sharedApplication];
        for (ScheduledTrip *oneSchedule in items) {
            
            UILocalNotification* notifyAlarm = [[UILocalNotification alloc]
                                                init];
            if (notifyAlarm) {
                notifyAlarm.fireDate = [[NSDate dateWithTimeIntervalSince1970:[oneSchedule.scheduledDepartureTime integerValue] ] dateByAddingTimeInterval:-60*60*([[defaults objectForKey:@"AlertTime"] floatValue]/60) ];
                notifyAlarm.timeZone = [NSTimeZone defaultTimeZone];
                notifyAlarm.repeatInterval = 0;
                //        notifyAlarm.soundName = @"bell_tree.mp3";
                notifyAlarm.alertBody = [NSString stringWithFormat:@"Your trip is scheduled to start in %.0f minutes.", [[defaults objectForKey:@"AlertTime"] floatValue]];
                [app scheduleLocalNotification:notifyAlarm];
                
                NSLog(@"fireDate: %@", [[NSDate dateWithTimeIntervalSince1970:[oneSchedule.scheduledDepartureTime integerValue] ] dateByAddingTimeInterval:-60*60*([[defaults objectForKey:@"AlertTime"] floatValue]/60) ]);
            }
            
            notifyAlarm = [[UILocalNotification alloc]
                           init];
            if (notifyAlarm) {
                notifyAlarm.fireDate = [[NSDate dateWithTimeIntervalSince1970:[oneSchedule.scheduledDepartureTime integerValue] ] dateByAddingTimeInterval:-60*5];
                notifyAlarm.timeZone = [NSTimeZone defaultTimeZone];
                notifyAlarm.repeatInterval = 0;
                //        notifyAlarm.soundName = @"bell_tree.mp3";
                notifyAlarm.alertBody = [NSString stringWithFormat:@"Your trip is scheduled to start in 5 minutes."];
                [app scheduleLocalNotification:notifyAlarm];
            }
        }
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.uitableview_routes deselectRowAtIndexPath:indexPath animated:YES];
    
    RouteDetailsViewController * routeDetailsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"routeDetailsViewController"];
    routeDetailsViewController.route_dic = self.route_dic;
    routeDetailsViewController.selected_route_number = indexPath.row;
    
    //
    NSMutableDictionary *route_dic_local = [((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row];
    
    NSMutableDictionary *result = [jsonParser getRouteDetails:route_dic_local];
    
    routeDetailsViewController.calculated_calories = [result objectForKey:@"CaloriesToBurn_number"];
    [self presentViewController:routeDetailsViewController animated:NO completion:nil];
    return;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //    NSMutableDictionary *route_dic_local = [((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:indexPath.row];
    
    //    NSMutableDictionary *result = [jsonParser getRouteDetails:route_dic_local];
    
    //    NSLog(@"start_time:%@", [result objectForKey:@"start_time"]);
    //    NSLog(@"end_time:%@", [result objectForKey:@"end_time"]);
    
    //    if ([[NSString stringWithFormat:@"%@",[result objectForKey:@"start_time"]] isEqualToString:@"(null)"]) {
    //        NSLog(@"(null)");
    //        return 0;
    //
    //    }
    
    return 100;
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)didTapGoBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateFromToAddressesFromLatLng
{
    self.uILabel_from.text = self.address_from;
    self.uILabel_to.text = self.address_to;
    
//    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
//    CLLocation *sectorLocation = [[CLLocation alloc] initWithLatitude:[[self.scheduled_route_param objectForKey:@"departureLat"] doubleValue]  longitude:[[self.scheduled_route_param objectForKey:@"departureLng"] doubleValue]];
//    [geocoder reverseGeocodeLocation:sectorLocation completionHandler:^(NSArray *placemarks, NSError *error) {
//        if (error == nil && [placemarks count] > 0) {
//            
//            CLPlacemark *placemark = [placemarks lastObject];
//            
//            placemark = [placemarks lastObject];
//            self.uILabel_from.text = [[@"" stringByAppendingString:[NSString stringWithFormat:@"%@ %@\n%@, %@ %@",
//                                                                    placemark.subThoroughfare, placemark.thoroughfare,
//                                                                    placemark.locality, placemark.administrativeArea, placemark.postalCode]] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
//            
//        } else {
//            NSLog(@"%@", error.debugDescription);
//        }
//    } ];
//    
//    CLGeocoder *geocoder2 = [[CLGeocoder alloc] init];
//    CLLocation *sectorLocation2 = [[CLLocation alloc] initWithLatitude:[[self.scheduled_route_param objectForKey:@"arrivalLat"] doubleValue]  longitude:[[self.scheduled_route_param objectForKey:@"arrivalLng"] doubleValue]];
//    [geocoder2 reverseGeocodeLocation:sectorLocation2 completionHandler:^(NSArray *placemarks2, NSError *error2) {
//        //        NSLog(@"reverseGeocodeLocation1");
//        if (error2 == nil && [placemarks2 count] > 0) {
//            //            NSLog(@"reverseGeocodeLocation2");
//            
//            CLPlacemark *placemark2 = [placemarks2 lastObject];
//            
//            placemark2 = [placemarks2 lastObject];
//            self.uILabel_to.text = [[@"" stringByAppendingString:[NSString stringWithFormat:@"%@ %@\n%@, %@ %@",
//                                                                  placemark2.subThoroughfare, placemark2.thoroughfare,
//                                                                  placemark2.locality, placemark2.administrativeArea, placemark2.postalCode]] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
//        } else {
//            NSLog(@"%@", error2.debugDescription);
//        }
//    } ];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"hh:mm a, MMM dd, yyyy"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setLocale:locale];
    
    if ([[self.scheduled_route_param objectForKey:@"departureTime"] doubleValue]==0) {
        self.uILabel_departTime.text = [@"Arrive by " stringByAppendingString: [df stringFromDate: [NSDate dateWithTimeIntervalSince1970:[[self.scheduled_route_param objectForKey:@"arrivalTime"] doubleValue] ]]];
    } else {
        //    NSLog(@"updateFromToAddressesFromLatLng: %f", [[self.scheduled_route_param objectForKey:@"departureTime"] doubleValue]/1000  );
        self.uILabel_departTime.text = [@"Depart at " stringByAppendingString:[df stringFromDate: [NSDate dateWithTimeIntervalSince1970:[[self.scheduled_route_param objectForKey:@"departureTime"] doubleValue] ]] ];
    }
    
    if ([[self.scheduled_route_param objectForKey:@"arrivalTime"] doubleValue]==0)
        self.uILabel_arrivalTime.text = @"";
    else
        self.uILabel_arrivalTime.text = [@"Arrive by " stringByAppendingString:[df stringFromDate: [NSDate dateWithTimeIntervalSince1970:[[self.scheduled_route_param objectForKey:@"arrivalTime"] doubleValue] ]] ];
    
    if ([[self.scheduled_route_param objectForKey:@"departureTime"] doubleValue]==0) {
        self.uILabel_arrivalTime.text = @"";
    }
    
}

@end
