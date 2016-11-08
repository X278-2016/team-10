//
//  BusAnnotationView.m
//  GCTC2
//
//  Created by Fangzhou Sun on 4/24/15.
//  Copyright (c) 2015 Fangzhou Sun. All rights reserved.
//

#import "BusAnnotationView.h"
#import "ColorConstants.h"
#import <QuartzCore/QuartzCore.h>

@implementation BusAnnotationView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        // Determine our start and stop angles for the arc (in radians)
//        self.startAngle = M_PI * 1.5;
//        endAngle = startAngle + (M_PI * 2);
        
    }
    return self;
}



- (void)drawRect:(CGRect)rect
{
//    UIGraphicsBeginImageContext( 48 );
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (!self.routeName)
        self.routeName = @"Bus Line";
    if (!self.busDistance)
        self.busDistance = 1.3;
    
    double percentage=70.0;
    double radius = 18;
    double width = 4;
    
    CGContextSetLineWidth(context, (CGFloat)radius);
    CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextAddArc(context, radius, radius, radius/2, -M_PI, 3*M_PI/2, NO);
    CGContextStrokePath(context);
    
    CGContextSetLineWidth(context, (CGFloat)width);
    
    CGContextSetStrokeColorWithColor(context, [DefaultRed CGColor]);
    CGContextAddArc(context, radius, radius, radius-width/2, 3*M_PI/2, -M_PI/2+M_PI*2*percentage/100, NO);
    CGContextStrokePath(context);
    
    CGContextSetStrokeColorWithColor(context, [DefaultGreen CGColor]);
    CGContextAddArc(context, radius, radius, radius-width/2, -M_PI/2+M_PI*2*percentage/100, 3*M_PI/2, NO);
    CGContextStrokePath(context);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, radius*2, radius*2)];
    [imageView setImage:[UIImage imageNamed:@"aiga_bus-128@2x.png"]];
    [self addSubview:imageView];
    
    CGRect titleLabelRectangle = CGRectMake(0, 0, 0, 0);
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:titleLabelRectangle];
    titleLabel.textColor = [UIColor colorWithRed:40/255.0 green:171/255.0 blue:227/255.0 alpha:1];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    //        titleLabel.text = [NSString stringWithFormat:@"Route %d",i+1];
//    titleLabel.text = @"Red Line\n49/70 seats\n1.3 mile";
    titleLabel.text = [NSString stringWithFormat:@"70%%"];
    titleLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:13];
    titleLabel.numberOfLines=0;
            [titleLabel sizeToFit];
    
    titleLabel.frame = CGRectMake(radius-titleLabel.frame.size.width/2, radius-titleLabel.frame.size.height/2, titleLabel.frame.size.width, titleLabel.frame.size.height);
    [self addSubview:titleLabel];
    
    CGRect title2LabelRectangle = CGRectMake(0, radius*2, radius*2, 12);
    UILabel *title2Label = [[UILabel alloc]initWithFrame:title2LabelRectangle];
    title2Label.textColor = [UIColor blackColor];
    //    titleLabel.backgroundColor = [UIColor darkGrayColor];
    title2Label.textAlignment = NSTextAlignmentCenter;
    //        titleLabel.text = [NSString stringWithFormat:@"Route %d",i+1];
    title2Label.text = @"\U0001F68C";
    title2Label.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:13];
    title2Label.numberOfLines=1;
    [self addSubview:title2Label];
}

- (UIImage *)snapshot:(UIView *)view routeName:(NSString *)routeName busDistance:(double)busDistance
{
    self.routeName = routeName;
    self.busDistance = busDistance;
    
    [self drawRect:self.frame];
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
