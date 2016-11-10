//
//  CalendarViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 4/26/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

/*
 This is the calendar view controller
 Users can use this view to manage their scheduled trips
*/

#import <UIKit/UIKit.h>
#import <Canvas.h>

@interface CalendarViewController : UIViewController <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *lbl_dateheader;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_Agenda;
@property (strong, nonatomic) IBOutlet CSAnimationView *CSAnimationView_Top;
@property (strong, nonatomic) IBOutlet UITableView *uitableview_agenda;
@property (weak, nonatomic) IBOutlet CSAnimationView *cSAnimationView_Table;

@property (strong, nonatomic) IBOutlet UIScrollView *uiscrollview_dates;
- (IBAction)didSelectedToday:(id)sender;

@property (strong, nonatomic) IBOutlet CSAnimationView *cSAnimationView_recurring;
@property (strong, nonatomic) IBOutlet UIDatePicker *uIDatePicker_recurring;

- (IBAction)didTap_recurring_cancel:(id)sender;
- (IBAction)didTap_recurring_done:(id)sender;


@end
