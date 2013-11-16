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

#import <MotionJpegImageView/MotionJpegImageView.h>

#define ZOOM_STEP 1.5

@interface RHEWebCamViewController ()

@property (strong, nonatomic) NSRegularExpression *regexRemoveHTMLTags;

@property (assign, nonatomic) BOOL isFirstTime;


- (void) handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer;
- (void) handleSingleTap:(UIGestureRecognizer *)gestureRecognizer;
- (NSRegularExpression *) regexRemoveHTMLTags;


@end


@implementation RHEWebCamViewController
{
    BOOL _switchNavBack;
    BOOL _statusBarHidden;
    BOOL _updateConstraints;
    BOOL _origNavBarHidden;
}


- (void)dealloc
{
    [self.imageView stop];
    [self.imageView removeObserver:self forKeyPath:@"image"];
}


- (void) viewDidLoad
{
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.automaticallyAdjustsScrollViewInsets = NO;

    _switchNavBack = YES;
    _statusBarHidden = NO;

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [_imageView addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:singleTap];

    [singleTap requireGestureRecognizerToFail:doubleTap];

    _imageView.backgroundColor = [UIColor whiteColor];

    [_scrollView setBackgroundColor:[UIColor whiteColor]];
    [_scrollView setCanCancelContentTouches:NO];
    _scrollView.clipsToBounds = NO;
    _scrollView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;

    UIBarButtonItem *refreshButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                       target:self
                                                                                       action:@selector(getPhoto)];
    self.navigationItem.rightBarButtonItem = refreshButtonItem;
    _isFirstTime = YES;

    [self.imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationItem.title = _stationName;

    _origNavBarHidden = [self.navigationController isNavigationBarHidden];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.edgesForExtendedLayout = UIRectEdgeAll;
    [[self navigationController] setNavigationBarHidden:NO animated:animated];

    [self initImageView];
    [self initZoom];
    [self getPhoto];
}


- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:animated];
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


- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
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


- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if ( gestureRecognizer.state == UIGestureRecognizerStateEnded ) {
        BOOL hidden = [[[self navigationController] navigationBar] isHidden];
        _statusBarHidden = !hidden;
        [[self navigationController] setNavigationBarHidden:!hidden animated:YES];
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.scrollView.backgroundColor = (hidden ? [UIColor whiteColor] : [UIColor blackColor] );
                             [self setNeedsStatusBarAppearanceUpdate];
                         }
         ];
    }
}


- (BOOL)prefersStatusBarHidden
{
    return _statusBarHidden;
}


#pragma mark - Utils


- (NSRegularExpression *)regexRemoveHTMLTags
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


- (void)initImageView
{
    [self.scrollView removeConstraints:self.scrollView.constraints];
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
    _updateConstraints = YES;

    if ( [[self.webCamURL path] rangeOfString:@".mjpg"].location != NSNotFound ) {
        [self.imageView setUrl:self.webCamURL];
        [self.imageView play];
        return;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:self.webCamURL];
    [self.imageView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       self.imageView.image = image;
                                   }
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       NSLog(@"failure: %@", error);
                                   }
     ];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( object == self.imageView ) {
        if ( [keyPath isEqualToString:@"image"] ) {
            if ( _updateConstraints && [change[@"new"] isKindOfClass:[UIImage class]] ) {
                _updateConstraints = NO;
                [self initImageView];
                [self initZoom];
            }
        }
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


@end
