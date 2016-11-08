//
//  TabBarController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 5/18/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

/*
 This is the tab bar controller
 This controller controls the tab bar items
 */

#import "TabBarController.h"
#import "ColorConstants.h"

@interface TabBarController ()

@end

@implementation TabBarController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITabBarItem *tabBarItem0 = [self.tabBar.items objectAtIndex:0];
    UITabBarItem *tabBarItem1 = [self.tabBar.items objectAtIndex:1];
    UITabBarItem *tabBarItem2 = [self.tabBar.items objectAtIndex:2];
    UITabBarItem *tabBarItem3 = [self.tabBar.items objectAtIndex:3];
    UITabBarItem *tabBarItem4 = [self.tabBar.items objectAtIndex:4];
    
    tabBarItem0.title = @"Planner";
    tabBarItem1.title = @"Trips";
    tabBarItem2.title = @"Real-time";
    tabBarItem3.title = @"Summary";
    tabBarItem4.title = @"Settings";
    //    tabBarItem4.title = @"Log out";
    
    //    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:12.0f], NSFontAttributeName, [UIColor darkGrayColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:40/255.0 green:141/255.0 blue:227/255.0 alpha:1]} forState:UIControlStateSelected];
    
    [[UITabBar appearance] setTintColor:[UIColor colorWithRed:40/255.0 green:141/255.0 blue:227/255.0 alpha:1]];
//    [[UITabBar appearance] setBarTintColor:[UIColor white]];
    
    
    //    tabBarItem0.image = [[UIImage imageNamed:@"tab_gallery.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    //    tabBarItem1.image = [[UIImage imageNamed:@"tab_track.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    //    tabBarItem2.image = [[UIImage imageNamed:@"tab_portrait.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    //    tabBarItem3.image = [[UIImage imageNamed:@"tab_about.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    //    tabBarItem4.image = [[UIImage imageNamed:@"tab_signout"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
//    tabBarItem0.image = [[UIImage imageNamed:@"tab_points.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    tabBarItem1.image = [[UIImage imageNamed:@"tab_track.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    tabBarItem2.image = [[UIImage imageNamed:@"tab_portrait.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    tabBarItem3.image = [[UIImage imageNamed:@"tab_logbook.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    tabBarItem4.image = [[UIImage imageNamed:@"tab_gallery.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    self.selectedIndex = 0;
}

- (void)viewWillLayoutSubviews
{
//    CGRect screenBound = [[UIScreen mainScreen] bounds];
//    
//    // Check if is landscape
//    if (screenBound.size.width>screenBound.size.height) {
//        if ((int)[[UIScreen mainScreen] bounds].size.width >= 568)
//            [self.tabBar setBackgroundImage:[UIImage imageNamed:@"background_bottom_portrait.png" ]];
//        else
//            [self.tabBar setBackgroundImage:[UIImage imageNamed:@"background_bottom_portrait_4s.png" ]];
//    } else {
//        [self.tabBar setBackgroundImage:[UIImage imageNamed:@"background_bottom.png" ]];
//    }
    
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSLog(@"%lu", (unsigned long)[[tabBar items] indexOfObject:item]);
    //    NSUInteger indexOfItem = [[tabBar items] indexOfObject:item];
    //
    //    if (indexOfItem==4) {
    //        SigninViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SigninViewController"];
    //        viewController.disabledAutoLogin = YES;
    //        [self presentViewController:viewController animated:NO completion:nil];
    //    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
