//
//  RouteDetailsViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 5/16/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "RouteDetailsViewController.h"
#import "JSONParser.h"
#import "CommonAPI.h"

@interface RouteDetailsViewController () {
    JSONParser *jsonParser;
    NSMutableArray *step_details_array;
}

@property (strong, nonatomic) GMSMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation RouteDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    jsonParser = [[JSONParser alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self initMap];
    

}

- (void)initMap
{
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:42.359879 longitude:-71.058616 zoom:14];
    self.mapView = [GMSMapView mapWithFrame:self.uIView_map.bounds camera:camera];
    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    self.mapView.indoorEnabled = NO;
    [self.uIView_map addSubview:self.mapView];
    
    [self showSelectedRoute];
    
    NSInteger selectedI = self.selected_route_number+1;
    
    self.uILabel_topTitle.text = [NSString stringWithFormat:@"OPTION %ld", (long)selectedI ];
    
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    NSLog(@"didTapMarker");
    return YES;
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
    return [step_details_array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"details_cell"];
    
    cell.textLabel.text = [step_details_array objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.uITableView_steps deselectRowAtIndexPath:indexPath animated:YES];
    return;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40;
}

-(void)updateSelectedRouteDetails {
    NSMutableDictionary *route_dic_local = [((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:self.selected_route_number];
    
    NSMutableDictionary *result = [jsonParser getRouteDetails:route_dic_local];
    
    self.uILabel_map_title.text = [NSString stringWithFormat:@"%@ %@ %@", [result objectForKey:@"date"], [result objectForKey:@"start_time"], [result objectForKey:@"end_time"]];
    
    self.uILabel_map_total.text = [result objectForKey:@"total_time"];
    self.uILabel_map_walk.text = [result objectForKey:@"walk_time"];
//    self.uILabel_map_mta_points.text = [result objectForKey:@"mta_points_map"];
    self.uILabel_map_mta_points.text = self.calculated_calories;
    self.uILabel_map_carbon_credits.text =  [NSString stringWithFormat: @"%.1f", [[result objectForKey:@"transit_distance_miles_number"] floatValue]] ;

}

- (void)showSelectedRoute {
    step_details_array = [[NSMutableArray alloc] initWithCapacity:5];
    
    [self updateSelectedRouteDetails];
    
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
        NSString *overview_polyline = [[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"overview_polyline"];
        NSArray *coordArray = [CommonAPI polylineWithEncodedString:overview_polyline];
        
        // Markers
        GMSMarker *tomarker =  [[GMSMarker alloc] init];
        tomarker.map = self.mapView;
        tomarker.icon = [UIImage imageNamed:@"redmarker@2x.png"];
        tomarker.position = [((CLLocation *)coordArray.lastObject) coordinate];
        
//        tomarker.position = CLLocationCoordinate2DMake([[[[leg_array objectForKey:@"end_location"] allValues] objectAtIndex:0] floatValue],[[[[leg_array objectForKey:@"end_location"] allValues] objectAtIndex:1] floatValue]);
        
        // Markers
        GMSMarker *frommarker =  [[GMSMarker alloc] init];
        frommarker.map = self.mapView;
        frommarker.icon = [UIImage imageNamed:@"greenmarker@2x.png"];
//        frommarker.position = CLLocationCoordinate2DMake([[[[leg_array objectForKey:@"start_location"] allValues] objectAtIndex:0] floatValue],[[[[leg_array objectForKey:@"start_location"] allValues] objectAtIndex:1] floatValue]);
        frommarker.position = [((CLLocation *)coordArray.firstObject) coordinate];
        
        
        double lat=[[[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"bounds"] objectForKey:@"north"] doubleValue];
        double lon=[[[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"bounds"] objectForKey:@"east"] doubleValue];
        if (lat<lon) {
            double t = lat;
            lat=lon;
            lon=t;
        }
        
        CLLocationCoordinate2D coordinateSouthWest = CLLocationCoordinate2DMake(
                                                                                lat,
                                                                                lon
                                                                                );
        lat=[[[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"bounds"] objectForKey:@"south"] doubleValue];
        lon=[[[[((NSMutableArray *)[self.route_dic objectForKey:@"routes"]) objectAtIndex:i] objectForKey:@"bounds"] objectForKey:@"west"] doubleValue];
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
        
        // UIEdgeInsetsMake ( CGFloat top, CGFloat left, CGFloat bottom, CGFloat right);
        GMSCameraPosition *camera = [self.mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(40+10+10, 10, 55+10, 10)];
        
//        self.mapView.camera = camera;
        [self.mapView animateToCameraPosition:camera];
        
//        return;
        
        NSMutableArray *steps_array = [leg_array objectForKey:@"steps"];
        NSEnumerator *enmueratorsteps_array = [steps_array objectEnumerator];
        NSMutableDictionary *step;
        while (step = [enmueratorsteps_array nextObject]) {
            
            if ([[step objectForKey:@"travel_mode"] isEqualToString:@"WALKING"]) {
                if (i==self.selected_route_number) {
                    [step_details_array addObject:[NSString stringWithFormat:@"\U0001F6B6 %@", [step objectForKey:@"instructions"]]];
                }
                
                NSArray *pathArray = [CommonAPI polylineWithEncodedString: [[step objectForKey:@"polyline"] objectForKey:@"points"]];
                NSEnumerator *enmueratorpathArray = [pathArray objectEnumerator];
                CLLocation *oneLocation;
                
                GMSMutablePath *path = [GMSMutablePath path];
                while (oneLocation = [enmueratorpathArray nextObject]) {
                    [path addCoordinate:[oneLocation coordinate]];
//                    [path addCoordinate:CLLocationCoordinate2DMake([[[onepath allValues] objectAtIndex:0] doubleValue], [[[onepath allValues] objectAtIndex:1] doubleValue])];
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
                
            }
            
            else if ([[step objectForKey:@"travel_mode"] isEqualToString:@"TRANSIT"]) {
                if (i==self.selected_route_number) {
                    [step_details_array addObject:[NSString stringWithFormat:@"\U0001F68C %@", [step objectForKey:@"instructions"]]];
                }
                
                NSArray *pathArray = [CommonAPI polylineWithEncodedString: [[step objectForKey:@"polyline"] objectForKey:@"points"]];
                NSEnumerator *enmueratorpathArray = [pathArray objectEnumerator];
                CLLocation *oneLocation;
                
                GMSMutablePath *path = [GMSMutablePath path];
                while (oneLocation = [enmueratorpathArray nextObject]) {
                    [path addCoordinate:[oneLocation coordinate]];
                    //                    [path addCoordinate:CLLocationCoordinate2DMake([[[onepath allValues] objectAtIndex:0] doubleValue], [[[onepath allValues] objectAtIndex:1] doubleValue])];
                }
                
                GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
                if (i==self.selected_route_number) {
                    
                    polyline.strokeColor = [colorArray objectAtIndex:(colorIndex++)%[colorArray count]];
                    polyline.strokeWidth = 6.f;
                    polyline.geodesic = YES;
                    
                    NSLog(@"TEST::: STEP:::%@", step);
                    
                    NSMutableDictionary *departure_stop = [[step objectForKey:@"transit"] objectForKey:@"departure_stop"];
                    NSMutableDictionary *arrival_stop = [[step objectForKey:@"transit"] objectForKey:@"arrival_stop"];
                    
                    GMSMarker *departure_stop_marker = [[GMSMarker alloc] init];
                    departure_stop_marker.title = [departure_stop objectForKey:@"name"];
                    departure_stop_marker.icon = [UIImage imageNamed:@"yellowmarker_small@2x.png"];
                    departure_stop_marker.position = ((CLLocation *)[CommonAPI polylineWithEncodedString:[[step objectForKey:@"polyline"] objectForKey:@"points"]].firstObject).coordinate;
//                    departure_stop_marker.position = CLLocationCoordinate2DMake([[[[departure_stop objectForKey:@"location"] allValues] objectAtIndex:0] doubleValue], [[[[departure_stop objectForKey:@"location"] allValues] objectAtIndex:1] doubleValue]);
                    departure_stop_marker.map = self.mapView;
                    
                    GMSMarker *arrival_stop_marker = [[GMSMarker alloc] init];
                    arrival_stop_marker.title = [arrival_stop objectForKey:@"name"];
                    arrival_stop_marker.icon = [UIImage imageNamed:@"yellowmarker_small@2x.png"];
                    
                    arrival_stop_marker.position = ((CLLocation *)[CommonAPI polylineWithEncodedString:[[step objectForKey:@"polyline"] objectForKey:@"points"]].lastObject).coordinate;
//                    arrival_stop_marker.position = CLLocationCoordinate2DMake([[[[arrival_stop objectForKey:@"location"] allValues] objectAtIndex:0] doubleValue], [[[[arrival_stop objectForKey:@"location"] allValues] objectAtIndex:1] doubleValue]);
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
    
    [self.uITableView_steps reloadData];
    //    [self showRealtimeBus];
    
    //    [realtimeUpdateTimer invalidate];
    //    //    [self didUpdateRealtimeData];
    //    realtimeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(showRealtimeBus) userInfo:nil repeats:YES];
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

- (IBAction)didTap_previous_route:(id)sender {
    
    NSInteger number_of_routes = [[self.route_dic objectForKey:@"routes"] count];
    self.selected_route_number = (self.selected_route_number+number_of_routes-1)%number_of_routes;
    
    NSInteger selectedI = self.selected_route_number+1;
    self.uILabel_topTitle.text = [NSString stringWithFormat:@"OPTION %ld", (long)selectedI ];
    
    [self showSelectedRoute];
}

- (IBAction)didTap_next_route:(id)sender {
    NSInteger number_of_routes = [[self.route_dic objectForKey:@"routes"] count];
    self.selected_route_number = (self.selected_route_number+number_of_routes+1)%number_of_routes;
    
    NSInteger selectedI = self.selected_route_number+1;
    self.uILabel_topTitle.text = [NSString stringWithFormat:@"OPTION %ld", (long)selectedI ];
    
    [self showSelectedRoute];
}

- (IBAction)didTapGoBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
