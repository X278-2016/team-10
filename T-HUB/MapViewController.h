//
//  MapViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 4/28/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Canvas.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>

@interface MapViewController : UIViewController <UIScrollViewDelegate, GMSMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_top;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_scroll;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_map;
@property (strong, nonatomic) IBOutlet UIScrollView *uiscrollview_routes;

@property (nonatomic, copy) NSMutableDictionary *route_dic;
@property (nonatomic, assign) NSInteger selected_route_number;

- (IBAction)btn_back:(id)sender;

@end
