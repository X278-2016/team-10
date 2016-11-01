//
//  SummaryTableViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 7/31/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "SummaryTableViewController.h"

@interface SummaryTableViewController ()

@end

@implementation SummaryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateLabels];
}

- (void)updateLabels {
    self.uILabel_time_walking.text = [NSString stringWithFormat:@"0.0 hr"];
    self.uILabel_time_taking_bus.text = [NSString stringWithFormat:@"0.0 hr"];
    self.uILabel_calories_burned.text = [NSString stringWithFormat:@"0"];
    self.uILabel_gas_saving.text = [NSString stringWithFormat:@"$ 0.00"];
    self.uILabel_transit_points.text = [NSString stringWithFormat:@"0.0 pts"];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"transit_time"]) {
        float tmp = [[defaults objectForKey:@"transit_time"] floatValue];
        self.uILabel_time_taking_bus.text = [NSString stringWithFormat:@"%.1f hr", tmp/3600];
        
        if (tmp<3600)
            self.uILabel_time_taking_bus.text = [NSString stringWithFormat:@"%.1f min", tmp/60];
    }
    if ([defaults objectForKey:@"walking_time"]) {
        float tmp = [[defaults objectForKey:@"walking_time"] floatValue];
        self.uILabel_time_walking.text = [NSString stringWithFormat:@"%.1f hr", tmp/3600];
        
        if (tmp<3600)
            self.uILabel_time_walking.text = [NSString stringWithFormat:@"%.1f min", tmp/60];
    }
    if ([defaults objectForKey:@"calories_burned"]) {
        self.uILabel_calories_burned.text = [NSString stringWithFormat:@"%.0f", [[defaults objectForKey:@"calories_burned"] floatValue]];
    }
    if ([defaults objectForKey:@"gas_saving"]) {
        self.uILabel_gas_saving.text = [NSString stringWithFormat:@"$ %.2f", [[defaults objectForKey:@"gas_saving"] floatValue]];
    }
    if ([defaults objectForKey:@"impact_points"]) {
        self.uILabel_transit_points.text = [NSString stringWithFormat:@"%.1f pts", [[defaults objectForKey:@"impact_points"] floatValue]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
