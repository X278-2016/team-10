//
//  EmbeddedBrowseTableViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 8/18/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "EmbeddedBrowseTableViewController.h"

@interface EmbeddedBrowseTableViewController ()

@end

@implementation EmbeddedBrowseTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isNearbyBusesShown = 0;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setIsNearbyBusesShownToInt:(int) i {
    self.isNearbyBusesShown = i;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    NSLog(@"selected:%@", [NSString stringWithFormat: @"%ld", (long)self.isNearbyBusesShown]);
//    if(indexPath.row == 0) {
//        if (self.isNearbyBusesShown==0) {
//            self.isNearbyBusesShown = 1;
//            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
//            
//        } else {
//            self.isNearbyBusesShown = 0;
//            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
//        }
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"tapNearbyBusesFromTheView" object:self];
//    }
}

@end
