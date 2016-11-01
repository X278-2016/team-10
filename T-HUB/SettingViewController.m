//
//  SettingViewController.m
//  GCTC2
//
//  Created by Fangzhou Sun on 4/14/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "SettingViewController.h"
#import <Canvas.h>

@implementation SettingViewController

- (void)viewDidLoad
{
    [self startAnimationToFadeEverything];
    
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self startAnimationToFadeEverything];
}

- (void)startAnimation {
    self.CSAnimationView_Top.type = CSAnimationTypeSlideDown;
    self.CSAnimationView_Top.duration = 0.3;
    self.CSAnimationView_Top.delay = 0.00;
    [self.CSAnimationView_Top startCanvasAnimation];
    
    self.CSAnimationView_Setting.type = CSAnimationTypeFadeIn;
    self.CSAnimationView_Setting.duration = 0.3;
    self.CSAnimationView_Setting.delay = 0.07;
    [self.CSAnimationView_Setting startCanvasAnimation];
    
    self.CSAnimationView_Top.alpha=1;
    self.CSAnimationView_Setting.alpha=1;
}

- (void)startAnimationToFadeEverything {
    self.CSAnimationView_Top.alpha=0;
    
    self.CSAnimationView_Setting.alpha=0;
}
@end
