//
//  RHCViewController.m
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "RHCViewController.h"
#import "RHCStationCell.h"
#import "RHEGraphView.h"

#import "RHEVindsidenAPIClient.h"
#import <MotionJpegImageView/MotionJpegImageView.h>
#import <JTSImageViewController/JTSImageViewController.h>

@import VindsidenKit;

static NSString *kCellID = @"stationCellID";

@interface RHCViewController ()<NSUserActivityDelegate, UIDataSourceModelAssociation>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) MotionJpegImageView *cameraView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) CDStation *pendingScrollToStation;
@property (assign, nonatomic) BOOL isShowingLandscapeView;
@property (assign, nonatomic) BOOL wasVisible;
@property (strong, nonatomic) NSMutableSet *transformedCells;


@end


@implementation RHCViewController


- (void)dealloc
{
    [self.cameraView removeObserver:self forKeyPath:@"image" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [self endObservingOrientation];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self beginObservingOrientation];

    self.automaticallyAdjustsScrollViewInsets = NO;

    UIButton *button = nil;
    UIBarButtonItem *bb = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(settings:)];

    UIBarButtonItem *bd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                        target:self
                                                                        action:@selector(share:)];

    button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [button addTarget:self action:@selector(info:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *bc = [[UIBarButtonItem alloc] initWithCustomView:button];

    MotionJpegImageView *imageView = [[MotionJpegImageView alloc] initWithFrame:CGRectMake( 0.0, 0.0, 44.0, 33.0)];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(camera:)];
    [imageView addGestureRecognizer:gesture];
    UIBarButtonItem *bt = [[UIBarButtonItem alloc] initWithCustomView:imageView];
    self.cameraView = imageView;
    [self.cameraView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];


    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.toolbar setItems:@[bd, flex, bt, flex, bc, flex, bb]];


    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
    self.pageControl.numberOfPages = [CDStation numberOfVisibleStations];

    _transformedCells = [NSMutableSet set];

    [[RHEVindsidenAPIClient defaultManager] fetchStations:^(BOOL success, NSArray *stations) {
        if ( success ) {
            [self updateStations:stations];
            [self updateCameraButton:YES];
            [self saveActivity];
        }
    }
                                                    error:^(NSError *error) {
                                                        [[RHCAlertManager defaultManager] showNetworkError:error];
                                                    }
     ];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}


- (void)viewDidLayoutSubviews
{
    if ( self.pendingScrollToStation ) {
        [self scrollToStation:self.pendingScrollToStation];
        self.pendingScrollToStation = nil;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ( _wasVisible ) {
        _wasVisible = NO;
        [self updateCameraButton:YES];
    }

    [self beginObservingOrientation];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _wasVisible = YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)shouldAutorotate
{
    return NO;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.collectionView.collectionViewLayout invalidateLayout];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    RHCStationCell *cell =  nil;

    if ( [self.collectionView.visibleCells count] ) {
        cell = [self.collectionView visibleCells].firstObject;
    }

    if ( [segue.identifier isEqualToString:@"ShowSettings"] ) {
        UINavigationController *navCon = segue.destinationViewController;
        RHCSettingsViewController *controller = navCon.viewControllers[0];
        controller.delegate = self;
    } else if ( [segue.identifier isEqualToString:@"ShowStationDetails"] ) {
        UINavigationController *navCon = segue.destinationViewController;
        RHEStationDetailsViewController *controller = navCon.viewControllers[0];
        controller.delegate = self;
        controller.station = cell.currentStation;
    } else if ( [segue.identifier isEqualToString:@"PresentGraphLandscape"] ) {
        RHCLandscapeGraphViewController *controller = segue.destinationViewController;
        controller.plots = cell.graphView.plots;
        controller.station = cell.currentStation;
    }
}


- (void)applicationDidBecomeActive:(NSNotification *)notificaiton
{
    static BOOL isFirst = YES;
    if ( NO == isFirst ) {
        if ( [[self.collectionView visibleCells] count] ) {
            RHCStationCell *cell = [self.collectionView visibleCells][0];
            [cell fetch];
            [self updateCameraButton:YES];
        }
    }
    isFirst = NO;
}


- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self updateCameraButton:NO];
}


#pragma mark - CollectionView Delegate


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self fetchedResultsController] sections][0];
    return [sectionInfo numberOfObjects];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    RHCStationCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    CDStation *station = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    cell.currentStation = station;

    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.collectionView.bounds.size;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ( scrollView != self.collectionView ) {
        return;
    }

    [self updateCameraButton:NO];

    for ( RHCStationCell *cell in [self.collectionView visibleCells] ) {
        [_transformedCells addObject:cell];

        if ( CGAffineTransformIsIdentity(cell.transform) ) {
            [UIView animateWithDuration:0.25
                             animations:^(void) {
                                 cell.transform = CGAffineTransformScale( CGAffineTransformIdentity, 0.94, 0.94);
                             }
             ];
        }
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ( scrollView != self.collectionView ) {
        return;
    }

    for ( RHCStationCell *cell in _transformedCells ) {
        [UIView animateWithDuration:0.10
                         animations:^(void) {
                             cell.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             [_transformedCells removeObject:cell];

                             NSIndexPath *indexPath = [self.collectionView indexPathsForVisibleItems][0];
                             [[Datamanager sharedManager].sharedDefaults setObject:@(indexPath.row) forKey:@"selectedIndexPath"];
                             [[Datamanager sharedManager].sharedDefaults synchronize];
                             [self updateCameraButton:YES];
                             self.pageControl.currentPage = indexPath.row;
                             [self saveActivity];
                         }
         ];
    }
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollViewDidEndDecelerating:scrollView];
}


#pragma mark - FetchedResultsController


- (NSFetchedResultsController *) fetchedResultsController
{
    if ( _fetchedResultsController ) {
        return _fetchedResultsController;
    }

    [NSFetchedResultsController deleteCacheWithName:@"StationList"];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSString *cacheName = @"StationList";

    NSManagedObjectContext *context = [[Datamanager sharedManager] managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDStation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isHidden == NO"];
    fetchRequest.predicate = predicate;

    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1];
    [fetchRequest setSortDescriptors:sortDescriptors];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:context
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:cacheName];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;

    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _fetchedResultsController;
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
        case NSFetchedResultsChangeDelete:
        case NSFetchedResultsChangeMove:
            [self.collectionView reloadData];
            self.pageControl.numberOfPages = [CDStation numberOfVisibleStations];
            [self saveActivity];
            break;
        case NSFetchedResultsChangeUpdate:
            break;
    }
}


- (void)updateStations:(NSArray *)stations
{
    [CDStation updateStations:stations completion:^(BOOL newStations) {
        if ( newStations ) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                           message:NSLocalizedString(@"ALERT_NEW_STATIONS_FOUND", @"New stations found. Go to settings to view them")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertController* __weak weakAlert = alert;
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [weakAlert dismissViewControllerAnimated:YES completion:nil];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];

    if ( [stations count] > 0 ) {
        [[Datamanager sharedManager].sharedDefaults setObject:[NSDate date] forKey:@"lastUpdated"];
        [[Datamanager sharedManager].sharedDefaults synchronize];
    }
}


- (void)updateCameraButton:(BOOL)update
{
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.cameraView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self.cameraView stop];

                         if ( NO == update ) {
                             return;
                         }

                         if ( [[self.collectionView visibleCells] count] == 0 ) {
                             return;
                         }

                         RHCStationCell *cell = [self.collectionView visibleCells][0];

                         if ( [cell.currentStation.webCamImage length] == 0 ) {
                             return;
                         }

                         [self.cameraView setUrl:[NSURL URLWithString:cell.currentStation.webCamImage]];
                         [self.cameraView play];
                         
                         [UIView animateWithDuration:0.25
                                          animations:^{
                                              self.cameraView.alpha = 1.0;
                                          }
                          ];
                     }
     ];
}


#pragma mark - Actions


- (IBAction)settings:(id)sender
{
    [self performSegueWithIdentifier:@"ShowSettings" sender:sender];
}


- (IBAction)info:(id)sender
{
    [self performSegueWithIdentifier:@"ShowStationDetails" sender:sender];
}


- (IBAction)share:(id)sender
{
    RHCStationCell *cell = [self.collectionView visibleCells][0];

    UIImage *shareImage = [UIImage imageFromView:cell];
    NSArray *activityProviders = @[shareImage];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityProviders applicationActivities:nil];

    activityViewController.excludedActivityTypes = @[UIActivityTypeAssignToContact];
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:activityViewController animated:YES completion:nil];

    UIPopoverPresentationController *presentationController = [activityViewController popoverPresentationController];
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;
    presentationController.barButtonItem = sender;
}


- (IBAction)camera:(id)sender
{
    if ( [[self.collectionView visibleCells] count] == 0 ) {
        return;
    }

    MotionJpegImageView *view = (MotionJpegImageView *)[(UITapGestureRecognizer *)sender view];

    if ( view.image ) {
        JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
        imageInfo.image = view.image;
        imageInfo.referenceRect = [view frame];
        imageInfo.referenceView = [view superview];

        JTSImageViewController *controller = [[JTSImageViewController alloc] initWithImageInfo:imageInfo
                                                                                          mode:JTSImageViewControllerMode_Image
                                                                               backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred|JTSImageViewControllerBackgroundOption_Scaled];

        [controller showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
    }
}


- (IBAction)pageControlChangedValue:(id)sender
{
    NSInteger page = [(UIPageControl *)sender currentPage];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:page inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}


#pragma mark - Station Details Delegate


- (void)rheStationDetailsViewControllerDidFinish:(RHEStationDetailsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Settings Delegate


- (void)rhcSettingsDidFinish:(RHCSettingsViewController *)controller
{
    if ( [[self.collectionView visibleCells] count] ) {
        RHCStationCell *cell = [self.collectionView visibleCells][0];
        [cell displayPlots];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( [keyPath isEqualToString:@"image"] ) {
        if ( [change[@"new"] isKindOfClass:[UIImage class]] ) {
            [self.cameraView pause];
        }
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


#pragma mark -

- (void)updateContentWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
{
    if ( self.fetchedResultsController.fetchedObjects.count ) {
        NSInteger __block remaining = self.fetchedResultsController.fetchedObjects.count;

        for ( CDStation *station in self.fetchedResultsController.fetchedObjects ) {
            [[RHEVindsidenAPIClient defaultManager] fetchStationsPlotsForStation:station.stationId
                                                                      completion:^(BOOL success, NSArray *plots) {
                                                                          DLOG(@"");
                                                                          if ( success ) {
                                                                              [CDPlot updatePlots:plots completion:nil];
                                                                          }
                                                                          remaining -= 1;
                                                                      } error:^(BOOL cancelled, NSError *error) {
                                                                      }
             ];
        }

        while (remaining > 0 ) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            DLOG(@"waiting: %ld", (long)remaining);
        }

        if ( completionHandler ) {
            completionHandler(UIBackgroundFetchResultNewData);
        }

    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}


- (void)scrollToStation:(CDStation *)station
{
    if ( self.collectionView ) {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:station];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        self.pageControl.currentPage = indexPath.row;
    } else {
        self.pendingScrollToStation = station;
    }
}


- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(deviceOrientation) && !_isShowingLandscapeView) {
        if ( self.presentedViewController ) {
            return;
        }
        _isShowingLandscapeView = YES;
        [self performSegueWithIdentifier:@"PresentGraphLandscape" sender:self];
    }
    else if (UIDeviceOrientationIsPortrait(deviceOrientation) && _isShowingLandscapeView) {
        if ( NO == [self.presentedViewController isKindOfClass:[RHCLandscapeGraphViewController class]] ) {
            return;
        }
        [self dismissViewControllerAnimated:YES completion:nil];
        _isShowingLandscapeView = NO;
    }
}


- (void)beginObservingOrientation
{
    _isShowingLandscapeView = NO;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


- (void)endObservingOrientation
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}


#pragma mark - NSUserActivity


- (void)userActivityWasContinued:(NSUserActivity *)userActivity
{
    DLOG(@"continued on other device");
}


- (void)updateUserActivityState:(NSUserActivity *)userActivity
{
    if ( [self.collectionView visibleCells].count > 0 ) {
        RHCStationCell *cell = [self.collectionView visibleCells][0];
        NSString *urlString = [NSString stringWithFormat:@"vindsiden://station/%@", cell.currentStation.stationId];
        NSDictionary *userInfo = @{
                                   @"urlToActivate" : urlString
                                   };

        userActivity.title = cell.currentStation.stationName;
        userActivity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://vindsiden.no/default.aspx?id=%@", cell.currentStation.stationId]];
        [userActivity addUserInfoEntriesFromDictionary:userInfo];
    }
}


- (void)saveActivity
{
    NSUserActivity *userActivity = self.userActivity;

    if (userActivity == nil) {
        userActivity = [[NSUserActivity alloc] initWithActivityType:[[NSBundle mainBundle] bundleIdentifier]];
        userActivity.delegate = self;
    }

    userActivity.needsSave = YES;
    self.userActivity = userActivity;
}


#pragma mark - Restoration


- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeInteger:self.pageControl.currentPage forKey:@"currentPage"];
}


- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    self.pageControl.currentPage = [coder decodeIntegerForKey:@"currentPage"];
}


- (NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)idx inView:(UIView *)view
{
    NSString *identifier = nil;

    if ( idx && view ) {
        CDStation *station = [[self fetchedResultsController] objectAtIndexPath:idx];
        identifier = [station.stationId stringValue];
    }

    return identifier;
}


- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view
{
    NSIndexPath *indexPath = nil;

    if ( identifier && view ) {
        NSNumber *stationId = @([identifier integerValue]);
        CDStation *station = [CDStation existingStation:stationId inManagedObjectContext:[self fetchedResultsController].managedObjectContext];
        if ( station ) {
            indexPath = [[self fetchedResultsController] indexPathForObject:station];
        }
    }
    return indexPath;
}

@end
