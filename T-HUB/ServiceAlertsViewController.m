//
//  ServiceAlertsViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 8/18/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "ServiceAlertsViewController.h"
#import "AFNetworking.h"
#import <ProtocolBuffers/ProtocolBuffers.h>
#import "GtfsRealtime.pb.h"
#import "ServiceAlertTableViewCell.h"


@interface ServiceAlertsViewController () {
    
    NSMutableArray *alerts_array;
}

@end

@implementation ServiceAlertsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.uITableView_serviceAlerts.estimatedRowHeight = 40;
    self.uITableView_serviceAlerts.rowHeight = UITableViewAutomaticDimension;
    self.uITableView_serviceAlerts.separatorStyle = NO;
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self getServiceAlerts];
//    [self.uITableView_serviceAlerts reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getServiceAlerts {
    
    alerts_array = [[NSMutableArray alloc] initWithCapacity:5];
    
    NSURL *URL = [NSURL URLWithString:@"http://ride.nashvillemta.org/TMGTFSRealTimeWebService/tripupdate/tripupdates.pb"];
    URL=[NSURL URLWithString:@"https://129.59.105.175/static/Data/Feed/alerts.pb"];
    URL = [NSURL URLWithString:@"http://transitdata.nashvillemta.org/TMGTFSRealTimeWebService/alert/alerts.pb"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    //    NSString *fileName = [URL lastPathComponent];
    
    AFHTTPRequestOperation *downloadRequest = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    downloadRequest.securityPolicy.allowInvalidCertificates = YES;
    
    [downloadRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // here we must create NSData object with received data...
        NSData *data = [[NSData alloc] initWithData:responseObject];
        FeedMessage *feedMessage = [FeedMessage parseFromData:data];
//         NSLog(@"feedMessage.entity: %@ ", feedMessage.entity);
        
        if (feedMessage)
            for (FeedEntity *feedEntity in feedMessage.entity) {
                Alert *alert = feedEntity.alert;
                
                NSLog(@"feedMessage.entity: %@ ", alert);
                [alerts_array addObject:alert];
//                for (Alert *alert in feedEntity.alert) {
//                    NSString *stopId = tripUpdateStopTimeUpdate.stopId;
//                    if ([stops_dic objectForKey:stopId]!=nil) {
//                        TripDescriptor *tripDescriptor = feedEntity.tripUpdate.trip;
//                        
//                        //                    NSLog(@"getTripUpdate:::%@, %@", stopId, tripDescriptor.tripId);
//                        TripUpdateStopTimeEvent *event = tripUpdateStopTimeUpdate.departure;
//                        
//                        NSMutableDictionary *one_route = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects: stopId, tripDescriptor.tripId, [NSString stringWithFormat:@"%lld", event.time ], nil] forKeys:[NSArray arrayWithObjects: @"stop_id", @"trip_id", @"time", nil]];
//                        
//                        int time_now = [[NSDate date] timeIntervalSince1970];
//                        
//                        if ([[one_route objectForKey:@"time"] intValue]<=time_now) continue;
//                        
//                        if ([nearbyBuses objectForKey: tripDescriptor.routeId]!=nil) {
//                            NSString *stopId2 = [[nearbyBuses objectForKey: tripDescriptor.routeId] objectForKey:@"stop_id"];
//                            float distance1= [[[stops_dic objectForKey:stopId2] objectForKey:@"stop_distance"] floatValue];
//                            float distance2= [[[stops_dic objectForKey:stopId] objectForKey:@"stop_distance"] floatValue];
//                            
//                            if (distance1>distance2) {
//                                [nearbyBuses setObject:one_route forKey:tripDescriptor.routeId];
//                            }
//                        } else {
//                            [nearbyBuses setObject:one_route forKey:tripDescriptor.routeId];
//                        }
//                        
//                    }
//                }
            }
        
        [self.uITableView_serviceAlerts reloadData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.uITableView_serviceAlerts reloadData];
        });
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"file downloading error : %@", [error localizedDescription]);
    }];
    
    // Step 5: begin asynchronous download
    [downloadRequest start];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //    return [route_array count];
    return [alerts_array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ServiceAlertTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceAlertCell"];
    cell.backgroundColor= [UIColor clearColor];
    cell.uILabel_title.text = @"test";
    cell.uILabel_subtitle.text = @"sb";
    
    Alert *alert =[alerts_array objectAtIndex:indexPath.row];
    
    NSArray *headerArray = alert.headerText.translation;
    for (id object in headerArray) {
        TranslatedStringTranslation *translatedStringTranslation = object;
        cell.uILabel_title.text = translatedStringTranslation.text;
    }
    
    NSArray *activePeriodArray = alert.activePeriod;
    for (id object in activePeriodArray) {
        cell.uILabel_subtitle.text = @"";
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"MMM dd, yyyy HH:mm"];
        
        TimeRange *timeRange =object;
        if (timeRange.hasStart) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeRange.start];
            cell.uILabel_subtitle.text =[cell.uILabel_subtitle.text stringByAppendingString:[format stringFromDate:date]];
        }
        if (timeRange.hasEnd) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeRange.end];
            cell.uILabel_subtitle.text =[cell.uILabel_subtitle.text stringByAppendingString:[NSString stringWithFormat:@" - %@",[format stringFromDate:date]]];
        }
        
    }
    
    NSArray *translationArray = alert.descriptionText.translation;
    for (id object in translationArray) {
        
        TranslatedStringTranslation *translatedStringTranslation = object;
        cell.uILabel_details.text = translatedStringTranslation.text;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.uITableView_serviceAlerts deselectRowAtIndexPath:indexPath animated:YES];
    
    return;
    
}


- (IBAction)didTapBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
