//
//  SettingTableViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 4/28/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "SettingTableViewController.h"
#import "AppDelegate.h"

@interface SettingTableViewController () {
    AppDelegate *appDelegate;
    UITextView *myUITextView;
}

@end

@implementation SettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.uiswitch_ServiceAlerts addTarget: self action: @selector(sendServiceAlerts:) forControlEvents:UIControlEventValueChanged];
    [self.uiswitch_Navigations addTarget: self action: @selector(sendNavigationNotifications:) forControlEvents:UIControlEventValueChanged];
    
    [self.uitextfield_busID addTarget: self action: @selector(setBusID:) forControlEvents:UIControlEventEditingChanged];
    
    [self.uISlider_alertTime addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.uISwitch_thubTimeBool addTarget:self action:@selector(thubTimeBoolValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.uISwitch_demoMode addTarget:self action:@selector(demoModeValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    // AppDelegate
    appDelegate = ((AppDelegate*)[[UIApplication sharedApplication]delegate]);
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"AlertTime"]) {
        self.uISlider_alertTime.value = [[defaults objectForKey:@"AlertTime"] floatValue];
        self.uILabel_alertTime.text = [NSString stringWithFormat:@"%.0f", self.uISlider_alertTime.value];
    }
    if ([defaults objectForKey:@"thubTimeBool"]) {
        [self.uISwitch_thubTimeBool setOn:[[defaults objectForKey:@"thubTimeBool"] boolValue] animated:YES];
    }
    if ([defaults objectForKey:@"demoMode"]) {
        [self.uISwitch_demoMode setOn:[[defaults objectForKey:@"demoMode"] boolValue] animated:YES];
    }
    
    
    if (!myUITextView) {
    myUITextView = [[UITextView alloc] initWithFrame:self.uIScrollView_ack.frame];
    myUITextView.text = @"This material is based upon work supported by the National Science Foundation under Grant No. 1528799.\n\nAny opinions, findings, and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.";
    myUITextView.textColor = [UIColor blackColor];
    myUITextView.font = [UIFont fontWithName:@"AvenirNext-Regular" size:13];
    [myUITextView setBackgroundColor:[UIColor clearColor]];
    myUITextView.editable = NO;
    myUITextView.scrollEnabled = YES;
//    myUITextView.textAlignment = NSTextAlignmentJustified;
    [self.uIScrollView_ack addSubview:myUITextView];
    }
    
    self.uILabel_currentVersion.text = [NSString stringWithFormat:@"Current version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

-(void)demoModeValueChanged:(UISlider *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSNumber numberWithBool:[self.uISwitch_demoMode isOn]] forKey:@"demoMode"];
    [defaults synchronize];
}


-(void)sliderValueChanged:(UISlider *)sender {
    self.uILabel_alertTime.text = [NSString stringWithFormat:@"%.0f", sender.value];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSNumber numberWithFloat:sender.value] forKey:@"AlertTime"];
    [defaults synchronize];
}

-(void)thubTimeBoolValueChanged:(UISlider *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[NSNumber numberWithBool:[self.uISwitch_thubTimeBool isOn]] forKey:@"thubTimeBool"];
    [defaults synchronize];
}

- (void)setBusID:(UITextField *)sender {
    appDelegate.selectedRouteNumber = [sender.text integerValue];
    NSLog(@"setBusID");
}

- (IBAction)sendServiceAlerts:(UISwitch *)sender {
    if (![sender isOn])
        return;
    NSDate *alertTime = [[NSDate date]
                         dateByAddingTimeInterval:5];
    UIApplication* app = [UIApplication sharedApplication];
    UILocalNotification* notifyAlarm = [[UILocalNotification alloc]
                                        init];
    if (notifyAlarm)
    {
        notifyAlarm.fireDate = alertTime;
        notifyAlarm.timeZone = [NSTimeZone defaultTimeZone];
        notifyAlarm.repeatInterval = 0;
        //        notifyAlarm.soundName = @"bell_tree.mp3";
        notifyAlarm.alertBody = @"Porter Square Station closed today due to construction.";
        [app scheduleLocalNotification:notifyAlarm];
    }
}

- (IBAction)sendNavigationNotifications:(UISwitch *)sender {
    
    if (![sender isOn])
        return;
    NSDate *alertTime = [[NSDate date]
                         dateByAddingTimeInterval:15];
    UIApplication* app = [UIApplication sharedApplication];
    UILocalNotification* notifyAlarm = [[UILocalNotification alloc]
                                        init];
    if (notifyAlarm)
    {
        notifyAlarm.fireDate = alertTime;
        notifyAlarm.timeZone = [NSTimeZone defaultTimeZone];
        notifyAlarm.repeatInterval = 0;
//        notifyAlarm.soundName = @"bell_tree.mp3";
        notifyAlarm.alertBody = @"Your bus is coming in 10 minutes. It's time to walk to the bus stop.";
        [app scheduleLocalNotification:notifyAlarm];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}

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

- (IBAction)didTapForMoreInfo:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://thub.isis.vanderbilt.edu/"]];
}
- (IBAction)didTapVideo:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://thub.isis.vanderbilt.edu/video"]];
}

- (IBAction)didTapSCOPE:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://scope.isis.vanderbilt.edu/"]];
}
@end
