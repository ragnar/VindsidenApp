//
//  RHEWebCamViewController.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 15.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol RHEWebCamImageViewDelegate;


@interface RHEWebCamViewController : UIViewController <UIScrollViewDelegate>

@property (weak, nonatomic) id<RHEWebCamImageViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (copy, nonatomic) NSURL *webCamURL;
@property (copy, nonatomic) NSString *stationName;
@property (copy, nonatomic) NSString *permitText;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *permitLabelConstraint;

- (IBAction) done:(id)sender;

@end

@protocol RHEWebCamImageViewDelegate <NSObject>

- (void) rheWebCamViewDidFinish:(RHEWebCamViewController *)controller;

@end