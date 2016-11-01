//
//  StatusView.m
//  MyDay
//
//  Created by Fangzhou Sun on 11/1/14.
//  Copyright (c) 2014 Fangzhou Sun. All rights reserved.
//

#import "StatusView.h"

@implementation StatusView

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

- (id)initWithText:(NSString *)text delayToHide:(float)delayToHide iconIndex:(int)iconIndex
{
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    
    //
    CGRect labelRectangle = CGRectMake(0, 0, 0, 15);
    UILabel *lbl_title = [[UILabel alloc]initWithFrame:labelRectangle];
    lbl_title.textColor = [UIColor whiteColor];
    lbl_title.text = text;
    lbl_title.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:20];
    lbl_title.numberOfLines=0;
    [lbl_title sizeToFit];
    
    CGFloat statusViewWidth = lbl_title.frame.size.width+45;
    CGFloat statusViewHeight = 93;
    
    CGRect statusViewRectangle = CGRectMake(screenBound.size.width/2-statusViewWidth/2, screenBound.size.height/2-statusViewHeight/2, statusViewWidth, statusViewHeight);
    self = [super initWithFrame:statusViewRectangle];
    if (self) {
        
//        CGRect imageViewRectangle = CGRectMake(0, 0, statusViewRectangle.size.width, statusViewRectangle.size.height);
//        UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageViewRectangle];
//        imageView.image = [UIImage imageNamed:@"statusViewBackground.png"];
//        [imageView setContentMode:UIViewContentModeScaleToFill];
//        [self addSubview:imageView];
        
        
        
        CGRect labelRectangle = CGRectMake(0, 0, 300, 15);
        UILabel *lbl_title = [[UILabel alloc]initWithFrame:labelRectangle];
        lbl_title.textColor = [UIColor whiteColor];
        lbl_title.text = text;
        lbl_title.font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:20];
        lbl_title.lineBreakMode = NSLineBreakByWordWrapping;
        lbl_title.numberOfLines=0;
        [lbl_title sizeToFit];
        lbl_title.textAlignment = NSTextAlignmentCenter;
        lbl_title.frame = CGRectMake(statusViewRectangle.size.width/2-lbl_title.frame.size.width/2, 58, lbl_title.frame.size.width, lbl_title.frame.size.height);
        
//        NSLog(@"lbl_title.frame.size.height:%f",lbl_title.frame.size.height);
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height+lbl_title.frame.size.height-27);
        
        CGRect imageViewRectangle = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageViewRectangle];
        imageView.image = [UIImage imageNamed:@"statusViewBackground.png"];
        [imageView setContentMode:UIViewContentModeScaleToFill];
        [self addSubview:imageView];
        
        if (iconIndex==0) {
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            spinner.frame = CGRectMake(statusViewRectangle.size.width/2 -37/2, 14, 37, 37);
            [spinner startAnimating];
            [self addSubview:spinner];
        } else if (iconIndex==1) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(statusViewRectangle.size.width/2 -45/2, 11, 44, 44)];
            imageView.image = [UIImage imageNamed:@"info44.png"];
            [imageView setContentMode:UIViewContentModeScaleToFill];
            [self addSubview:imageView];
        }
        
        //
//        CGRect frame2 = lbl_title.frame;
        
        
        [self addSubview:lbl_title];
        
        if (delayToHide>0)
            [self performSelector:@selector(hideView) withObject:nil afterDelay:delayToHide];
        else
            [self performSelector:@selector(hideView) withObject:nil afterDelay:5];
    }
    return self;
}

- (void)hideView {
    [self removeFromSuperview];
}

- (void)rePostion {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGRect statusViewRectangle = CGRectMake(screenBound.size.width/2-self.frame.size.width/2, screenBound.size.height/2-self.frame.size.height/2, self.frame.size.width, self.frame.size.height);
    self.frame = statusViewRectangle;
}


- (void)setText:(NSString *)text {
    self.label.text = text;
}


@end
