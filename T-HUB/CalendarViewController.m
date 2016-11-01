//
//  CalendarViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 4/26/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "CalendarViewController.h"
#import "ColorConstants.h"
#import "CalendarTableViewCell.h"
#import "AppDelegate.h"

#import "JSONParser.h"
#import <ProtocolBuffers/ProtocolBuffers.h>
#import "GtfsRealtime.pb.h"
#import "PlannerViewController.h"
#import "AFNetworking.h"
#import "ScheduledTrip.h"
#import "RealtimeViewController.h"

enum ViewStatus {
    ViewStatus_calendarView,
    ViewStatus_recurringView
};

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]

@interface CalendarViewController () {
    NSInteger selectedDate;
    
    AppDelegate *appDelegate;
    
    //    NSMutableArray *calendarArray;
    NSArray *scheduleArray;
    
    NSMutableArray *routeScrollArray;
    
    JSONParser *jsonParser;
    
    enum ViewStatus viewStatus;
    
    //    NSMutableDictionary *route_dic_local;
    NSString *scheduled_trip_id;
    
    FeedMessage *serviceAlert_feedMessage;
    
    //    NSMutableArray *route_details_toBeDeleted;
    
    NSManagedObjectContext* objectContext;
    ScheduledTrip *scheduledTrip_recurring;
    
    NSTimeInterval startTimeInterval;
    NSTimeInterval endTimeInterval;
}

@end

@implementation CalendarViewController

- (void)viewDidLoad {
    [self startAnimationToFadeEverything];
    
    [super viewDidLoad];
    
    objectContext = [CoreDataHelper managedObjectContext];
    
    jsonParser = [[JSONParser alloc] init];
    
    //    [self updateTopDateLabel:0];
    
    [self initDateScroll];
    
    // AppDelegate
    appDelegate = ((AppDelegate*)[[UIApplication sharedApplication]delegate]);
    self.cSAnimationView_recurring.hidden = YES;
    selectedDate = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //    route_details_toBeDeleted = [[NSMutableArray alloc] init];
    
    [self getAlertUpdates];
    
    [self initWeekdayButtonsForRecurring];
    
    if (appDelegate.calendar_added_schedule_timestamp)
        if (appDelegate.calendar_added_schedule_timestamp>0) {
            NSDate *updatetimestamp = [NSDate dateWithTimeIntervalSince1970:appDelegate.calendar_added_schedule_timestamp];
            [self updateSelectedDateOnScroll: [self daysBetweenDate:[NSDate date] andDate:updatetimestamp]];
        }
    appDelegate.calendar_added_schedule_timestamp=0;
    
    
    [self startAnimation];
    
    [self loadCalendarsFromDatabase];
    [self.uitableview_agenda reloadData];
    
    viewStatus = ViewStatus_calendarView;
    [self UpdateViewByViewStatus];
    
    // Long press gesture
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.2; //seconds
    lpgr.delegate = self;
    [self.uitableview_agenda addGestureRecognizer:lpgr];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self startAnimationToFadeEverything];
    
    //    for (UIView *view in route_details_toBeDeleted) {
    //        [view removeFromSuperview];
    //    }
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    //    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    //    {
    //        // Long press detected, start the timer
    //        startTimeInterval = [[NSDate date] timeIntervalSince1970];
    //    }
    //    else
    //    {
    //        if (gestureRecognizer.state == UIGestureRecognizerStateCancelled
    //            || gestureRecognizer.state == UIGestureRecognizerStateFailed
    //            || gestureRecognizer.state == UIGestureRecognizerStateEnded)
    //        {
    //            endTimeInterval = [[NSDate date] timeIntervalSince1970];
    //            NSLog(@"TMP:::HOLD:::%f", endTimeInterval-startTimeInterval);
    //            // Long press ended, stop the timer
    //        }
    //    }
    
    
    CGPoint p = [gestureRecognizer locationInView:self.uitableview_agenda];
    
    NSIndexPath *indexPath = [self.uitableview_agenda indexPathForRowAtPoint:p];
    if (indexPath == nil) {
        NSLog(@"long press on table view but not on a row");
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"long press on table view at section %ld", (long)indexPath.section);
        
        
        
        ScheduledTrip *scheduledTrip = [scheduleArray objectAtIndex:indexPath.section];
        if (scheduledTrip.googleTripDic && scheduledTrip.googleTripDic.length>0) {
            // Check if in Nashville
            if (![self checkIfIsInNashvilleWithLatitude: [scheduledTrip.departureLat floatValue] andLongitude: [scheduledTrip.departureLng floatValue]] || ![self checkIfIsInNashvilleWithLatitude: [scheduledTrip.arrivalLat floatValue] andLongitude: [scheduledTrip.arrivalLng floatValue]]) {
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
            
            NSString *tmp = [scheduledTrip.googleTripDic stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *tripDic = [NSPropertyListSerialization
                                            propertyListWithData:[tmp dataUsingEncoding:NSUTF8StringEncoding]
                                            options:kNilOptions
                                            format:NULL
                                            error:NULL];
            
            RealtimeViewController * realtimeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RealtimeViewController"];
            realtimeViewController.calendar_searchID = scheduledTrip.searchID;
            realtimeViewController.calendar_route_dic_from_database = tripDic;
            realtimeViewController.calendar_ScheduledTrip_uuid = scheduledTrip.uuid;
            
            
            [self presentViewController:realtimeViewController animated:YES completion:nil];
        }
        
        
    } else {
        NSLog(@"gestureRecognizer.state = %ld", (long)gestureRecognizer.state);
    }
    
}

- (Boolean)checkIfIsInNashvilleWithLatitude: (float) latitude andLongitude: (float) longitude {
    if (latitude<36.621473 && longitude> -87.545533 && latitude> 35.758253 && longitude<-86.201456)
        return YES;
    else
        return NO;
}

- (NSString *)checkIfSomeServiceAlertsAffectTheRouteIDs:(NSArray *) routeIDsArray {
    NSString *returnStr = nil;
    for (FeedEntity *feedEntity in serviceAlert_feedMessage.entity) {
        NSArray *informedEntityArray = feedEntity.alert.informedEntity;
        
        for (EntitySelector* element in informedEntityArray) {
            if ([self checkIfNSStringExistInArray:element.routeId routeIDsArray:routeIDsArray]) {
                NSArray *headerArray = feedEntity.alert.headerText.translation;
                for (id object in headerArray) {
                    TranslatedStringTranslation *translatedStringTranslation = object;
                    if (!returnStr)
                        returnStr = @"";
                    returnStr = [returnStr stringByAppendingString:translatedStringTranslation.text];
                    returnStr = [returnStr stringByAppendingString:@"\n"];
                }
                break;
            }
        }
    }
    return returnStr;
}

- (BOOL)checkIfNSStringExistInArray:(NSString *) str routeIDsArray: (NSArray *)routeIDsArray {
    for (NSString *routeID in routeIDsArray) {
        if ([str isEqualToString:routeID]) {
            return YES;
        }
    }
    return NO;
}

- (void)getAlertUpdates {
    
    //    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"alerts" ofType:@"pb"];
    //    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    //    serviceAlert_feedMessage = [FeedMessage parseFromData:fileData];
    
    //
    //    for (FeedEntity *feedEntity in feedMessage.entity) {
    //        NSLog(@"headerText%@", feedEntity.alert.headerText);
    //        NSArray *informedEntityArray = feedEntity.alert.informedEntity;
    //
    //        for (EntitySelector* element in informedEntityArray) {
    //            NSLog(@"1107: %@", element.routeId);
    //        }
    //    }
    
    
    NSURL *URL = [NSURL URLWithString:@"http://transitdata.nashvillemta.org/TMGTFSRealTimeWebService/alert/alerts.pb"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    //    NSString *fileName = [URL lastPathComponent];
    
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        // here we must create NSData object with received data...
        NSData *data = [[NSData alloc] initWithData:responseObject];
        serviceAlert_feedMessage = [FeedMessage parseFromData:data];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
    
    
}

- (void)UpdateViewByViewStatus {
    switch (viewStatus) {
        case ViewStatus_calendarView:
            self.cSAnimationView_recurring.hidden = YES;
            break;
        case ViewStatus_recurringView: {
            [self.uIDatePicker_recurring setMinimumDate:[NSDate date]];
            self.cSAnimationView_recurring.hidden = NO;
            
            [self.CSAnimationView_Agenda bringSubviewToFront:self.cSAnimationView_recurring];
            self.cSAnimationView_recurring.type = CSAnimationTypeBounceUp;
            self.cSAnimationView_recurring.duration = 0.3;
            self.cSAnimationView_recurring.delay = 0.0;
            [self.cSAnimationView_recurring startCanvasAnimation];
            break;
        }
        default:
            break;
    }
}


-(NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

-(NSDate *)beginningOfDay:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    return [calendar dateFromComponents:components];
}

- (NSDate *)endOfDay:(NSDate *)date0
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [NSDateComponents new];
    components.day = 1;
    
    NSDate *date = [calendar dateByAddingComponents:components
                                             toDate:[self beginningOfDay:date0]
                                            options:0];
    
    date = [date dateByAddingTimeInterval:-1];
    
    return date;
}

- (void)loadCalendarsFromDatabase {
    NSDate *now = [NSDate date];
    NSDate *newDate = [now dateByAddingTimeInterval:60*60*24*selectedDate];
    
    NSDate *begin = [self beginningOfDay:newDate];
    NSDate *end = [self endOfDay:newDate];
    
    // Core Data
    NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"departureTime>%@ AND departureTime<%@", [NSNumber numberWithInteger:[begin timeIntervalSince1970]], [NSNumber numberWithInteger:[end timeIntervalSince1970]] ] inManagedObjectContext:objectContext];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"departureTime"
                                                                 ascending:YES];
    scheduleArray = [items sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
    [self.uitableview_agenda reloadData];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    
    return [scheduleArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //    return [route_array count];
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *deleteOneAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        //        for (UIView *view in route_details_toBeDeleted) {
        //            [view removeFromSuperview];
        //        }
        [objectContext deleteObject:[scheduleArray objectAtIndex:indexPath.section]];
        [CoreDataHelper saveManagedObjectContext:objectContext];
        
        [self loadCalendarsFromDatabase];
        [self.uitableview_agenda reloadData];
        
        [self updateLocalNotifications];
        [self.uitableview_agenda setEditing:NO];
    }];
    
    UITableViewRowAction *deleteRecurringAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete\nRecurring"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        //        for (UIView *view in route_details_toBeDeleted) {
        //            [view removeFromSuperview];
        //        }
        ScheduledTrip *scheduledTrip = [scheduleArray objectAtIndex:indexPath.section];
        //        if ([scheduledTrip.isRecurring intValue]==1) {
        // Core Data
        NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"searchID==%@ AND isRecurring==%@", scheduledTrip.searchID, [NSNumber numberWithInteger:1] ] inManagedObjectContext:objectContext];
        
        if ([items count]>0) {
            for (ScheduledTrip *oneSchedule in items) {
                [objectContext deleteObject:oneSchedule];
            }
        }
        [CoreDataHelper saveManagedObjectContext:objectContext];
        //        }
        //        [objectContext deleteObject:[scheduleArray objectAtIndex:indexPath.row]];
        
        [self loadCalendarsFromDatabase];
        [self.uitableview_agenda reloadData];
        
        [self updateLocalNotifications];
        [self.uitableview_agenda setEditing:NO];
    }];
    
    return @[deleteOneAction, deleteRecurringAction];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"blurAction4");
        
    } else {
        NSLog(@"blurAction3");
    }
}

- (NSMutableDictionary *)getScheduledRoute:(NSInteger)local_scheduled_trip_id {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    NSString *query = [NSString stringWithFormat:@"SELECT one_route_dic FROM thub_scheduled_routes WHERE scheduled_trip_id=%ld", (long)local_scheduled_trip_id];
    
    NSArray *responseInfo;
    
    responseInfo = [[NSArray alloc] initWithArray:[appDelegate.dbManager loadDataFromDB:query]];
    NSMutableArray *responseArray =  [responseInfo mutableCopy];
    
    if ([responseArray count]>0) {
        //        localCalendar = [calendarArray objectAtIndex:0];
        NSString *tmp = [[[responseArray objectAtIndex:0] objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        result = [NSPropertyListSerialization
                  propertyListWithData:[tmp dataUsingEncoding:NSUTF8StringEncoding]
                  options:kNilOptions
                  format:NULL
                  error:NULL];
        
        return result;
    }
    return nil;
}

-(void)setRecurring:(UIButton *)sender {
    NSLog(@"setRecurring,%u",viewStatus);
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.uitableview_agenda];
    NSIndexPath *indexPath = [self.uitableview_agenda indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil)
    {
        if (viewStatus==ViewStatus_calendarView) {
            scheduledTrip_recurring = [scheduleArray objectAtIndex:indexPath.section];
            viewStatus=ViewStatus_recurringView;
        } else
            viewStatus=ViewStatus_calendarView;
        [self UpdateViewByViewStatus];
    }
}

- (void)scheduleRoute:(UIButton *)sender {
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.uitableview_agenda];
    NSIndexPath *indexPath = [self.uitableview_agenda indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil)
    {
        //        for (UIView *view in route_details_toBeDeleted) {
        //            [view removeFromSuperview];
        //        }
        ScheduledTrip *scheduledTrip = [scheduleArray objectAtIndex:indexPath.section];
        appDelegate.reschedule_route_dictionary = [[NSMutableDictionary alloc] init];
        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.departureLat forKey:@"departureLat"];
        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.departureLng forKey:@"departureLng"];
        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.arrivalLat forKey:@"arrivalLat"];
        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.arrivalLng forKey:@"arrivalLng"];
        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.departureTime forKey:@"departureTime"];
        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.arrivalTime forKey:@"arrivalTime"];
        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.fromAddress forKey:@"fromAddress"];
        [appDelegate.reschedule_route_dictionary setObject: scheduledTrip.toAddress forKey:@"toAddress"];
        
        [objectContext deleteObject:[scheduleArray objectAtIndex:indexPath.section]];
        [CoreDataHelper saveManagedObjectContext:objectContext];
        
        self.tabBarController.selectedIndex=0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScheduledTrip *scheduledTrip = [scheduleArray objectAtIndex:indexPath.section];
    
    if (scheduledTrip.googleTripDic && scheduledTrip.googleTripDic.length>0) {
        NSString *tmp = [scheduledTrip.googleTripDic stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *tripDic = [NSPropertyListSerialization
                                        propertyListWithData:[tmp dataUsingEncoding:NSUTF8StringEncoding]
                                        options:kNilOptions
                                        format:NULL
                                        error:NULL];
        NSMutableDictionary *parsedDic = [jsonParser getRouteDetails:tripDic];
        CalendarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CalendarTableViewCell"];
        cell.lbl_from.text = [@"From: " stringByAppendingString:scheduledTrip.fromAddress];
        cell.lbl_to.text = [@"To: " stringByAppendingString:scheduledTrip.toAddress];
        cell.lbl_depart_arrive_time.text = [NSString stringWithFormat:@"%@  %@", scheduledTrip.departureText, scheduledTrip.arrivalText];
        
        NSMutableArray *route_details_array = [[parsedDic objectForKey:@"route_details_array"] copy];
        float length_route_details = 0.0;
        CGRect screenBound = [[UIScreen mainScreen] bounds];
        //        UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0, 128, 0, screenBound.size.height)];
        
        UIView *aView = [(UILabel *)cell.contentView viewWithTag:99];
        if (aView) {
            [aView removeFromSuperview];
        }
        aView = [[UIView alloc] initWithFrame:CGRectMake(0, 128, 0, screenBound.size.height)];
        aView.tag = 99;
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
        //        [route_details_toBeDeleted addObject:aView];
        [cell.contentView addSubview:aView];
        
        cell.lbl_route_times.text = [parsedDic objectForKey:@"route_times"];
        cell.lbl_start_time.text = [parsedDic objectForKey:@"start_time"];
        cell.lbl_end_time.text = [parsedDic objectForKey:@"end_time"];
        
        NSString *serviceAlerts = [self checkIfSomeServiceAlertsAffectTheRouteIDs:[parsedDic objectForKey:@"routeIDs"]];
        if (serviceAlerts) {
            cell.uIButton_serviceAlert.hidden = NO;
        } else {
            cell.uIButton_serviceAlert.hidden = YES;
        }
        cell.uIButton_serviceAlert.tag = indexPath.section;
        
        [cell.uibtn_scheduleRoute addTarget:self action:@selector(scheduleRoute:) forControlEvents:UIControlEventTouchUpInside];
        [cell.uibtn_setRecurring addTarget:self action:@selector(setRecurring:) forControlEvents:UIControlEventTouchUpInside];
        [cell.uIButton_serviceAlert addTarget:self action:@selector(showServiceAlertView:) forControlEvents:UIControlEventTouchUpInside];
        
        // Hold Instruction
        NSDate *startDate = [parsedDic objectForKey:@"date_start_time"];
        NSDate *endDate = [parsedDic objectForKey:@"date_end_time"];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([startDate timeIntervalSince1970]<([[NSDate date] timeIntervalSince1970]+60*60*([[defaults objectForKey:@"AlertTime"] floatValue]/60)) && [endDate timeIntervalSince1970]>[[NSDate date] timeIntervalSince1970]) {
            if ([scheduledTrip.checkpoint intValue]>-1) {
                cell.uILabel_titleForScheduledRoute.text = @"  HOLD TO RESUME NAVIGATION";
                cell.uILabel_titleForScheduledRoute.backgroundColor = DefaultOrange;
            } else {
                cell.uILabel_titleForScheduledRoute.text = @"  HOLD TO START NAVIGATION";
                cell.uILabel_titleForScheduledRoute.backgroundColor = TopBarRealtimeGoColor;
            }
        } else {
            cell.uILabel_titleForScheduledRoute.text = @"  SCHEDULED ROUTE";
            cell.uILabel_titleForScheduledRoute.backgroundColor = [UIColor lightGrayColor];
        }
        
        return cell;
    } else {
        CalendarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CalendarTableViewCell2"];
        cell.lbl_from.text = [@"From: " stringByAppendingString:scheduledTrip.fromAddress];
        cell.lbl_to.text = [@"To: " stringByAppendingString:scheduledTrip.toAddress];
        cell.lbl_depart_arrive_time.text = [NSString stringWithFormat:@"%@  %@", scheduledTrip.departureText, scheduledTrip.arrivalText];
        [cell.uibtn_scheduleRoute addTarget:self action:@selector(scheduleRoute:) forControlEvents:UIControlEventTouchUpInside];
        [cell.uibtn_setRecurring addTarget:self action:@selector(setRecurring:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //    NSArray *keys=[[savedAgenda objectForKey:self.lbl_dateheader.text] allKeys];
    //    NSMutableDictionary *oneRouteDic = [[savedAgenda objectForKey:self.lbl_dateheader.text] objectForKey:[keys objectAtIndex:section]];
    //
    //    NSMutableDictionary *leg_array = [[oneRouteDic objectForKey:@"legs"] objectAtIndex:0];
    //
    //
    //    NSString *sectionName = [NSString stringWithFormat:@"%@ - %@", [[leg_array objectForKey:@"departure_time"] objectForKey:@"text"], [[leg_array objectForKey:@"arrival_time"] objectForKey:@"text"]];
    //    return sectionName;
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.uitableview_agenda deselectRowAtIndexPath:indexPath animated:NO];
    
    //    MapViewController * mapViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mapViewController"];
    //    mapViewController.route_dic = route_dic;
    //    mapViewController.selected_route_number = indexPath.row;
    //    [self presentViewController:mapViewController animated:NO completion:nil];
    return;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    ScheduledTrip *scheduledTrip = [scheduleArray objectAtIndex:indexPath.section];
    
    if (scheduledTrip.googleTripDic && scheduledTrip.googleTripDic.length>0)
        return 195;
    else
        return 112;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10;
}

- (void)showServiceAlertView:(UIButton *)sender {
    ScheduledTrip *scheduledTrip = [scheduleArray objectAtIndex:sender.tag];
    
    if (scheduledTrip.googleTripDic && scheduledTrip.googleTripDic.length>0) {
        NSString *tmp = [scheduledTrip.googleTripDic stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *tripDic = [NSPropertyListSerialization
                                        propertyListWithData:[tmp dataUsingEncoding:NSUTF8StringEncoding]
                                        options:kNilOptions
                                        format:NULL
                                        error:NULL];
        NSMutableDictionary *parsedDic = [jsonParser getRouteDetails:tripDic];
        NSString *serviceAlerts = [self checkIfSomeServiceAlertsAffectTheRouteIDs:[parsedDic objectForKey:@"routeIDs"]];
        
        NSString *message = [NSString stringWithFormat:@"%@\nYour scheduled route might be delayed and need to be rescheduled.", serviceAlerts];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Service Alert"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Got it", nil];
        [alert show];
    }
}

- (void)initDateScroll {
    
    routeScrollArray = [[NSMutableArray alloc] init];
    
    //    CGFloat cellHeight = self.uiscrollview_dates.frame.size.height;
    CGFloat cellHeight = 67;
    CGFloat cellWidth = cellHeight*0.70;
    
    CGFloat scrollViewContentWidth = 0;
    
    UIColor *borderColor = [UIColor lightGrayColor];
    
    NSDate *now = [NSDate date];
    
    
    
    for (int i=0; i< 50; i++) {
        
        NSDate *newDate = [now dateByAddingTimeInterval:60*60*24*i];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        dateFormatter.dateFormat=@"MMM";
        NSString *text_month = [[dateFormatter stringFromDate:newDate] capitalizedString];
        dateFormatter.dateFormat=@"EEE";
        NSString * text_weekday = [[dateFormatter stringFromDate:newDate] capitalizedString];
        dateFormatter.dateFormat=@"dd";
        NSString * text_day = [[dateFormatter stringFromDate:newDate] capitalizedString];
        
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(scrollViewContentWidth, 0, cellWidth, cellHeight)];
        view.tag = i;
        [routeScrollArray addObject:view];
        view.layer.borderColor = borderColor.CGColor;
        view.layer.borderWidth = 0.0f;
        
        
        //        if (i==self.selected_route_number) {
        //            view.layer.borderColor = DefaultYellow.CGColor;
        //            view.layer.borderWidth = 3.0f;
        //        }
        
        CGRect monthLabelRectangle = CGRectMake(0, 0, cellWidth, 22);
        UILabel *monthLabel = [[UILabel alloc]initWithFrame:monthLabelRectangle];
        monthLabel.textColor = [UIColor whiteColor];
        monthLabel.backgroundColor = [UIColor darkGrayColor];
        monthLabel.textAlignment = NSTextAlignmentCenter;
        monthLabel.text = text_weekday;
        monthLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:13];
        monthLabel.numberOfLines=1;
        [view addSubview:monthLabel];
        monthLabel.tag=0;
        
        
        CGRect weekdayLabelRectangle = CGRectMake(0, 22, cellWidth, 24);
        UILabel *weekdayLabel = [[UILabel alloc]initWithFrame:weekdayLabelRectangle];
        weekdayLabel.textColor = [UIColor blackColor];
        weekdayLabel.textAlignment = NSTextAlignmentCenter;
        weekdayLabel.text = text_month;
        weekdayLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:13];
        weekdayLabel.numberOfLines=1;
        [view addSubview:weekdayLabel];
        weekdayLabel.tag=1;
        
        CGRect dayLabelRectangle = CGRectMake(0, 46, cellWidth, 22);
        UILabel *dayLabel = [[UILabel alloc]initWithFrame:dayLabelRectangle];
        dayLabel.textColor = [UIColor blackColor];
        dayLabel.textAlignment = NSTextAlignmentCenter;
        dayLabel.text = text_day;
        dayLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:13];
        dayLabel.numberOfLines=1;
        [view addSubview:dayLabel];
        
        dayLabel.tag=2;
        
        //button for touch
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:@"" forState:UIControlStateNormal];
        btn.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
        [btn setBackgroundColor:[UIColor clearColor]];
        
        [btn addTarget:self action:@selector(didSelectDate:) forControlEvents:UIControlEventTouchDown];
        
        [view addSubview:btn];
        
        [self.uiscrollview_dates addSubview:view];
        
        
        scrollViewContentWidth += cellWidth;
    }
    
    
    self.uiscrollview_dates.contentSize = CGSizeMake(scrollViewContentWidth, cellHeight );
    
    [self updateSelectedDateOnScroll:0];
    
}

- (void)updateSelectedDateOnScroll:(long) i {
    
    if (i==0) {
        [self.uiscrollview_dates setContentOffset:
         CGPointMake(0, -self.uiscrollview_dates.contentInset.top) animated:YES];
    }
    
    //
    UIView *oldSelectedView = [routeScrollArray objectAtIndex:selectedDate];
    for (UIView *i in oldSelectedView.subviews){
        if([i isKindOfClass:[UILabel class]]){
            UILabel *dayLabel = (UILabel *)i;
            if(dayLabel.tag >0){
                dayLabel.backgroundColor = [UIColor clearColor];
            }
        }
    }
    
    selectedDate = i;
    
    //
    UIView *newSelectedView = [routeScrollArray objectAtIndex:selectedDate];
    for (UIView *i in newSelectedView.subviews){
        if([i isKindOfClass:[UILabel class]]){
            UILabel *dayLabel = (UILabel *)i;
            if(dayLabel.tag >0){
                dayLabel.backgroundColor = DefaultYellow;
            }
        }
    }
    
    [self updateTopDateLabel:i];
    
    [self loadCalendarsFromDatabase];
    
}


- (void)didSelectDate:(id)sender {
    
    UIButton *btn = (UIButton *)sender;
    UIView *newSelectedView = btn.superview;
    
    [self updateSelectedDateOnScroll:newSelectedView.tag];
    
    //    [self.uitableview_agenda reloadData];
    
}


- (void)updateTopDateLabel:(long) i {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    NSDate *date = [NSDate date];
    date = [date dateByAddingTimeInterval:60*60*24*i];
    
    NSString *formattedDateString = [[dateFormatter stringFromDate:date] uppercaseString];
    
    
    self.lbl_dateheader.text = [@"   " stringByAppendingString:formattedDateString];
}

- (void)startAnimation {
    self.CSAnimationView_Top.type = CSAnimationTypeSlideDown;
    self.CSAnimationView_Top.duration = 0.3;
    self.CSAnimationView_Top.delay = 0.00;
    [self.CSAnimationView_Top startCanvasAnimation];
    
    self.CSAnimationView_Agenda.type = CSAnimationTypeFadeIn;
    self.CSAnimationView_Agenda.duration = 0.3;
    self.CSAnimationView_Agenda.delay = 0.07;
    [self.CSAnimationView_Agenda startCanvasAnimation];
    
    self.cSAnimationView_Table.type = CSAnimationTypeFadeIn;
    self.cSAnimationView_Table.duration = 0.3;
    self.cSAnimationView_Table.delay = 0.3;
    [self.cSAnimationView_Table startCanvasAnimation];
    
    self.CSAnimationView_Top.alpha=1;
    self.CSAnimationView_Agenda.alpha=1;
    self.cSAnimationView_Table.alpha=1;
}

- (void)startAnimationToFadeEverything {
    self.CSAnimationView_Top.alpha=0;
    self.CSAnimationView_Agenda.alpha=0;
    self.cSAnimationView_Table.alpha=0;
}

- (IBAction)didSelectedToday:(id)sender {
    [self updateSelectedDateOnScroll:0];
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)initWeekdayButtonsForRecurring {
    NSArray *subviews = [self.cSAnimationView_recurring subviews];
    
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

- (IBAction)didTap_recurring_cancel:(id)sender {
    viewStatus=ViewStatus_calendarView;
    [self UpdateViewByViewStatus];
}

- (IBAction)didTap_recurring_done:(id)sender {
    
    NSArray *subviews = [self.cSAnimationView_recurring subviews];
    //
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            if (subview.tag)
                if (subview.tag>0) {
                    UIButton *button = (UIButton *)subview;
                    
                    NSDate *datePicked = self.uIDatePicker_recurring.date;
                    
                    for (int i=1; i<=[self daysBetweenDate:[NSDate date] andDate:datePicked]; i++) {
                        NSLog(@"r: %d",i);
                        NSDate *today = [NSDate date];
                        today = [today dateByAddingTimeInterval:60*60*24*i ];
                        
                        NSCalendar *calendar = [NSCalendar currentCalendar];
                        NSDateComponents *components = [calendar components:NSCalendarUnitWeekday fromDate:today];
                        NSInteger weekday = [components weekday]-1;
                        //                        if (weekday==0) weekday=7;
                        
                        if (button.tag>10)
                            if (((button.tag-10)%7)== weekday) {
                                NSInteger departureTime_i = [scheduledTrip_recurring.departureTime integerValue];
                                if (departureTime_i!=0) {
                                    
                                    departureTime_i = departureTime_i + 60*60*24*(i-[self daysBetweenDate:[NSDate date] andDate:[NSDate dateWithTimeIntervalSince1970:departureTime_i]]);
                                }
                                NSInteger arrivalTime_i = [scheduledTrip_recurring.arrivalTime integerValue];
                                
                                if (arrivalTime_i!=0) {
                                    arrivalTime_i = arrivalTime_i + 60*60*24*(i-[self daysBetweenDate:[NSDate date] andDate:[NSDate dateWithTimeIntervalSince1970:arrivalTime_i]]);
                                }
                                
                                ScheduledTrip *scheduledTrip = [CoreDataHelper insertManagedObjectOfClass:[ScheduledTrip class] inManagedObjectContext:objectContext ];
                                scheduledTrip.arrivalLat = scheduledTrip_recurring.arrivalLat;
                                scheduledTrip.arrivalLng = scheduledTrip_recurring.arrivalLng;
                                scheduledTrip.arrivalText = scheduledTrip_recurring.arrivalText;
                                scheduledTrip.arrivalTime = [NSNumber numberWithInteger: arrivalTime_i];
                                scheduledTrip.departureLat = scheduledTrip_recurring.departureLat;
                                scheduledTrip.departureLng = scheduledTrip_recurring.departureLng;
                                scheduledTrip.departureText = scheduledTrip_recurring.departureText;
                                scheduledTrip.departureTime = [NSNumber numberWithInteger: departureTime_i];
                                scheduledTrip.fromAddress = scheduledTrip_recurring.fromAddress;
                                scheduledTrip.toAddress = scheduledTrip_recurring.toAddress;
                                scheduledTrip.googleTripDic = nil;
                                scheduledTrip.isRecurring = [NSNumber numberWithInt:1];
                                scheduledTrip.searchID = scheduledTrip_recurring.searchID;
                                scheduledTrip.checkpoint = [NSNumber numberWithInt:-1];
                                scheduledTrip.uuid = [[NSUUID UUID] UUIDString];
                                scheduledTrip.scheduledDepartureTime = nil;
                                [CoreDataHelper saveManagedObjectContext:objectContext];
                                
                            }
                    }
                }
        }
    }
    
    viewStatus=ViewStatus_calendarView;
    [self UpdateViewByViewStatus];
}

-(void)updateLocalNotifications {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDate *now = [NSDate date];
    
    NSInteger nowTimestamp = (NSInteger)[now timeIntervalSince1970];
    
    // Core Data
    NSArray* items = [CoreDataHelper fetchEntitiesForClass:[ScheduledTrip class] withPredicate:[NSPredicate predicateWithFormat:@"scheduledDepartureTime>%@ ", [NSNumber numberWithInteger:nowTimestamp] ] inManagedObjectContext:objectContext];
    
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

@end
