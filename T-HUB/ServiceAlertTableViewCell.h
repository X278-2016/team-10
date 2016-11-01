//
//  ServiceAlertTableViewCell.h
//  T-HUB
//
//  Created by Fangzhou Sun on 8/18/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServiceAlertTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *uILabel_title;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_subtitle;
@property (weak, nonatomic) IBOutlet UILabel *uILabel_details;

@end
