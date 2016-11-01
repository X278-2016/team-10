//
//  UserConsentViewController.h
//  T-HUB
//
//  Created by Fangzhou Sun on 9/9/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserConsentViewController : UIViewController
- (IBAction)didTap_acceptAndContinue:(id)sender;
- (IBAction)didTap_learnMore:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *uILabel_consent;

@end
