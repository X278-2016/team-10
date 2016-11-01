//
//  RouteDetailsViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 5/16/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Canvas.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>

@interface RouteDetailsViewController : UIViewController <GMSMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_top;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_map;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_steps;

@property (strong, nonatomic) IBOutlet UILabel *uILabel_map_title;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_map_total;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_map_walk;
@property (strong, nonatomic) IBOutlet UIView *uIView_map;
@property (strong, nonatomic) IBOutlet UITableView *uITableView_steps;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_map_mta_points;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_map_carbon_credits;

@property (strong, nonatomic) NSMutableDictionary *route_dic;
@property (nonatomic, assign) NSInteger selected_route_number;
@property (strong, nonatomic) IBOutlet UILabel *uILabel_topTitle;
@property (nonatomic) NSString *calculated_calories;
@property (nonatomic) NSNumber *transit_distance_miles_number;

- (IBAction)didTap_previous_route:(id)sender;
- (IBAction)didTap_next_route:(id)sender;
- (IBAction)didTapGoBack:(id)sender;
@end
