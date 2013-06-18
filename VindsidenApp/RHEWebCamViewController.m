//
//  RHEWebCamViewController.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 15.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import "RHEWebCamViewController.h"
#import "RHEVindsidenAPIClient.h"
#import <UIImageView+AFNetworking.h>

#define ZOOM_STEP 1.5

@interface RHEWebCamViewController ()

@property (strong, nonatomic) NSRegularExpression *regexRemoveHTMLTags;

@property (assign, nonatomic) BOOL isFirstTime;
@property (assign, nonatomic) UIStatusBarStyle originalStatusBarStyle;
@property (assign, nonatomic) UIBarStyle originalBarStyle;
@property (strong, nonatomic) UIColor *originalTintColor;


- (void) handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer;
- (void) handleSingleTap:(UIGestureRecognizer *)gestureRecognizer;
- (NSRegularExpression *) regexRemoveHTMLTags;


@end


@implementation RHEWebCamViewController
{
    BOOL _switchNavBack;
}


- (void) viewDidLoad
{
    [super viewDidLoad];

    _switchNavBack = YES;

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [_imageView addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [_imageView addGestureRecognizer:singleTap];

    [singleTap requireGestureRecognizerToFail:doubleTap];

    _imageView.backgroundColor = [UIColor blackColor];

    [_scrollView setBackgroundColor:[UIColor blackColor]];
    [_scrollView setCanCancelContentTouches:NO];
    _scrollView.clipsToBounds = YES;
    _scrollView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;

    UIBarButtonItem *refreshButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                       target:self
                                                                                       action:@selector(getPhoto)];
    self.navigationItem.rightBarButtonItem = refreshButtonItem;
    _isFirstTime = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationItem.title = _stationName;

    _originalStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    _originalBarStyle = self.navigationController.navigationBar.barStyle;
    _originalTintColor = self.navigationController.navigationBar.tintColor;

//    [self setWantsFullScreenLayout:YES];
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
//    [self.navigationController.navigationBar setTintColor:nil];
//    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
//    [[self navigationController] setNavigationBarHidden:NO animated:animated];

    [self initImageView];
    [self initZoom];
    [self getPhoto];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

//    if ( _switchNavBack ) {
//        [[UIApplication sharedApplication] setStatusBarStyle:_originalStatusBarStyle animated:animated];
//        [self.navigationController.navigationBar setBarStyle:_originalBarStyle];
//        [self.navigationController.navigationBar setTintColor:_originalTintColor];
//    }
}


- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - Actions


- (void)done:(id)sender
{
    _switchNavBack = NO;
    [_delegate rheWebCamViewDidFinish:self];
}


#pragma mark - UIScrollView Delegates


-(UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


#pragma mark - UIGestureRecognizer


- (void) handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if ( gestureRecognizer.state == UIGestureRecognizerStateEnded ) {
        if ( _scrollView.zoomScale >= _scrollView.maximumZoomScale ) {
            [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
        } else {
            float newScale = [_scrollView zoomScale] * ZOOM_STEP;
            [self.scrollView setZoomScale:newScale animated:YES];
        }
    }
}


- (void) handleSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if ( gestureRecognizer.state == UIGestureRecognizerStateEnded ) {
        BOOL hidden = [[[self navigationController] navigationBar] isHidden];

        [[UIApplication sharedApplication] setStatusBarHidden:!hidden withAnimation:UIStatusBarAnimationFade];
        [[self navigationController] setNavigationBarHidden:!hidden animated:YES];
    }
}


#pragma mark - Utils


- (NSRegularExpression *) regexRemoveHTMLTags
{
    if ( _regexRemoveHTMLTags ) {
        return _regexRemoveHTMLTags;
    }

    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<[^>]+>)"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    _regexRemoveHTMLTags = regex;
    return regex;
}


- (void) initImageView
{
    [self.scrollView removeConstraints: self.scrollView.constraints];
    [self addConstraintsForImageEdges];
    [self addConstraintsToCenterImage];
}


- (void) addConstraintsForImageEdges
{
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=0@750)-[_imageView]-(>=0@250)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_imageView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0@750)-[_imageView]-(>=0@250)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_imageView)]];
}


- (void) addConstraintsToCenterImage
{
    NSLayoutConstraint *constraintMiddleY = [NSLayoutConstraint constraintWithItem:self.imageView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.scrollView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1.0
                                                                          constant:0.0];
    constraintMiddleY.priority = 100;
    [self.view addConstraint:constraintMiddleY];

    NSLayoutConstraint *constraintMiddleX = [NSLayoutConstraint constraintWithItem:self.imageView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.scrollView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0];
    constraintMiddleX.priority = 100;
    [self.view addConstraint:constraintMiddleX];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSTimeInterval duration = 0.25;
    [UIView animateWithDuration:duration
                     animations:^{
                         [self initImageView];
                         [self initZoom];
                     }
     ];
}


- (void) initZoom
{
    float minZoom = MIN(self.view.bounds.size.width / self.imageView.image.size.width, self.view.bounds.size.height / self.imageView.image.size.height);
    //if (minZoom > 1) return;

    self.scrollView.minimumZoomScale = minZoom;
    self.scrollView.zoomScale = minZoom;
}



- (void)getPhoto
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.webCamURL];
    [self.imageView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       self.imageView.image = image;
                                       [self initImageView];
                                       [self initZoom];
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       NSLog(@"failure: %@", error);
                                   }
     ];
}

@end
