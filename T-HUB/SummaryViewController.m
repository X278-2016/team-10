//
//  SummaryViewController.m
//  GCTC2
//
//  Created by Fangzhou Sun on 4/14/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "SummaryViewController.h"

@implementation SummaryViewController

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
    
    self.CSAnimationView_Content.type = CSAnimationTypeFadeIn;
    self.CSAnimationView_Content.duration = 0.3;
    self.CSAnimationView_Content.delay = 0.07;
    [self.CSAnimationView_Content startCanvasAnimation];
    
    self.CSAnimationView_Top.alpha=1;
    self.CSAnimationView_Content.alpha=1;
}

- (void)startAnimationToFadeEverything {
    self.CSAnimationView_Top.alpha=0;
    
    self.CSAnimationView_Content.alpha=0;
}

@end
