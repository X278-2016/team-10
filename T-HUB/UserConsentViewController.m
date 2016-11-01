//
//  UserConsentViewController.m
//  T-HUB
//
//  Created by Fangzhou Sun on 9/9/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "UserConsentViewController.h"
#import "TabBarController.h"
#import "AppData.h"

@interface UserConsentViewController ()

@end

@implementation UserConsentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.uILabel_consent.textAlignment = NSTextAlignmentJustified;
//    [self.view setHidden:YES];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    // Check if consent accepted.
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    if ([defaults objectForKey:@"ConsentAccepted"]) {
//        [self didTap_acceptAndContinue:Nil];
//    } else {
//        [self.view setHidden:NO];
//    }
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

- (IBAction)didTap_acceptAndContinue:(id)sender {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"ConsentAccepted"];
//    [defaults synchronize];
    NSManagedObjectContext* context = [CoreDataHelper managedObjectContext];
    
    AppData* appData = [CoreDataHelper insertManagedObjectOfClass:[AppData class] inManagedObjectContext:context];
    
    appData.userConsent = @"YES";
    
    [CoreDataHelper saveManagedObjectContext:context];
    
    UITabBarController *vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MainTabBarController"];
    
    [self presentViewController:vc animated:NO completion:nil];
}

- (IBAction)didTap_learnMore:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://gctc.isis.vanderbilt.edu/"]];
}
@end
