//
//  RHCViewController.m
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//
#import "VindsidenApp-Swift.h"

#import "RHCViewController.h"
#import "RHCStationCell.h"
#import "RHEGraphView.h"

#import <MotionJpegImageView/MotionJpegImageView.h>
#import <JTSImageViewController/JTSImageViewController.h>

@import WatchConnectivity;
@import CoreSpotlight;
@import VindsidenKit;


static NSString *kCellID = @"stationCellID";

@interface RHCViewController ()<NSUserActivityDelegate, UIDataSourceModelAssociation, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, RHEStationDetailsDelegate, RHCSettingsDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) MotionJpegImageView *cameraView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) CDStation *pendingScrollToStation;
@property (assign, nonatomic) BOOL isShowingLandscapeView;
@property (assign, nonatomic) BOOL wasVisible;
@property (strong, nonatomic) NSMutableSet *transformedCells;

@property (strong, nonatomic) NSIndexPath *currentIndexPath;
@property (assign, nonatomic) CGSize cellSize;

@property (strong, nonatomic) NSArray<NSLayoutConstraint *> *cameraViewConstraints;

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

    [[self collectionView] setContentInsetAdjustmentBehavior: UIScrollViewContentInsetAdjustmentNever];

    UIButton *button = nil;

    button = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"gear"] target:self action:@selector(settings:)];
    UIBarButtonItem *bb = [[UIBarButtonItem alloc] initWithCustomView:button];

//    UIBarButtonItem *bb = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
//                                                           style:UIBarButtonItemStylePlain
//                                                          target:self
//                                                          action:@selector(settings:)];

    UIBarButtonItem *bd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                        target:self
                                                                        action:@selector(share:)];

    button = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"info.circle"] target:self action:@selector(info:)];

    UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [button addInteraction: interaction];
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
    self.pageControl.numberOfPages = [CDStation numberOfVisibleStationsInManagedObjectContext:[DataManager shared].viewContext];


    _transformedCells = [NSMutableSet set];

    StationFetcher *fetcher = [[StationFetcher alloc] init];
    [fetcher fetch:^( NSArray *stations, NSError * __nullable error) {

        if ( error ) {
            [[RHCAlertManager defaultManager] showNetworkError:error];
        } else {
            [self updateStations:stations];
            [self updateCameraButton:YES];
            [self saveActivity];
        }
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ( _wasVisible ) {
        _wasVisible = NO;
        [self updateCameraButton:YES];
    }
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


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    if (@available(iOS 11, *)) {
        if ( _cameraViewConstraints == nil) {
            _cameraView.translatesAutoresizingMaskIntoConstraints = NO;

            NSLayoutConstraint *heightConstraint = [_cameraView.heightAnchor constraintEqualToConstant:32];
            NSLayoutConstraint *widthConstraint = [_cameraView.widthAnchor constraintEqualToConstant:140];

            _cameraViewConstraints = @[heightConstraint, widthConstraint];

            [heightConstraint setActive:YES];
            [widthConstraint setActive:YES];
        }
    }

    if ( CGSizeEqualToSize(self.cellSize, CGSizeZero) == NO ) {
        self.cellSize = self.collectionView.bounds.size;
    }

    [self.collectionView.collectionViewLayout invalidateLayout];

}


- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if ( CGSizeEqualToSize(self.cellSize, CGSizeZero) == NO ) {
        self.cellSize = self.collectionView.bounds.size;
    }

    if ( self.pendingScrollToStation && self.currentIndexPath == nil ) {
        [self scrollToStation:self.pendingScrollToStation];
        self.pendingScrollToStation = nil;
    }

    if ( self.currentIndexPath != nil && self.fetchedResultsController.fetchedObjects.count > 0 ) {
        [self.collectionView scrollToItemAtIndexPath:self.currentIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    }
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


- (BOOL)shouldAutorotate
{
    return NO;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    RHCStationCell *cell =  nil;

    if ( [self.collectionView.visibleCells count] ) {
        cell = [self.collectionView visibleCells].firstObject;
    }

    if ( [segue.identifier isEqualToString:@"ShowSettings"] ) {
        UINavigationController *navCon = segue.destinationViewController;
        RHCSettingsViewController *controller = navCon.viewControllers.firstObject;
        controller.delegate = self;
        navCon.presentationController.delegate = controller;
    } else if ( [segue.identifier isEqualToString:@"ShowStationDetails"] ) {
        UINavigationController *navCon = segue.destinationViewController;
        RHEStationDetailsViewController *controller = navCon.viewControllers.firstObject;
        controller.delegate = self;
        controller.station = cell.currentStation;
        controller.showButtons = true;
    } else if ( [segue.identifier isEqualToString:@"PresentGraphLandscape"] ) {
        UINavigationController *navCon = segue.destinationViewController;

        RHCLandscapeGraphViewController *controller = navCon.viewControllers.firstObject;
        controller.plots = cell.graphView.plots;
        controller.station = cell.currentStation;
    }
}


#pragma mark - Notifications


- (void)applicationDidBecomeActive:(NSNotification *)notificaiton
{
    static BOOL isFirst = YES;
    if ( NO == isFirst ) {
        self.fetchedResultsController = nil;
        [self.collectionView reloadData];
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
    if ( CGSizeEqualToSize(self.cellSize, CGSizeZero) ) {
        self.cellSize = self.collectionView.bounds.size;
    }

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

    self.currentIndexPath = [self.collectionView indexPathsForVisibleItems].firstObject;


    for ( RHCStationCell *cell in _transformedCells ) {
        [UIView animateWithDuration:0.10
                         animations:^(void) {
                             cell.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             [self->_transformedCells removeObject:cell];

                             NSIndexPath *indexPath = [self.collectionView indexPathsForVisibleItems].firstObject;
                             [[AppConfig sharedConfiguration].applicationUserDefaults setObject:@(indexPath.row) forKey:@"selectedIndexPath"];
                             [[AppConfig sharedConfiguration].applicationUserDefaults synchronize];
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

    NSManagedObjectContext *context = [DataManager shared].viewContext;
    NSFetchRequest *fetchRequest = CDStation.fetchRequest;
    [fetchRequest setFetchBatchSize:20];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isHidden == NO"];
    fetchRequest.predicate = predicate;

    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1];
    [fetchRequest setSortDescriptors:sortDescriptors];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:context
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:nil];
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
            self.pageControl.numberOfPages = [CDStation numberOfVisibleStationsInManagedObjectContext:[DataManager shared].viewContext];
            [self saveActivity];
            break;
        case NSFetchedResultsChangeUpdate:
        {
            RHCStationCell *cell = (RHCStationCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            cell.currentStation = anObject;
        }
            break;
    }
}


- (void)updateStations:(NSArray *)stations
{
    [CDStation updateWithFetchedContent: stations inManagedObjectContext:[DataManager shared].viewContext completionHandler:^(BOOL newStations) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( newStations ) {

                [[WindManager sharedManager] updateNow];

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

            [self updateApplicationContextToWatch];
            [[DataManager shared] indexVisibleStations];
        });
    }];

    if ( [stations count] > 0 ) {
        [[AppConfig sharedConfiguration].applicationUserDefaults setObject:[NSDate date] forKey:@"lastUpdated"];
        [[AppConfig sharedConfiguration].applicationUserDefaults synchronize];
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

- (void)rhcSettingsDidFinish:(RHCSettingsViewController *)controller shouldDismiss:(BOOL)shouldDismiss
{
    [self updateApplicationContextToWatch];
    [(RHCAppDelegate *)[[UIApplication sharedApplication] delegate] updateShortcutItems];
    [[WindManager sharedManager] updateNow];

    if ( [[self.collectionView visibleCells] count] ) {
        RHCStationCell *cell = [self.collectionView visibleCells][0];
        [cell displayPlots];
    }

    if (shouldDismiss) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
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


- (void)scrollToStation:(CDStation *)station
{
    if ( self.collectionView ) {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:station];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
        self.currentIndexPath = indexPath;
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

        dispatch_async(dispatch_get_main_queue(), ^{
            self->_isShowingLandscapeView = YES;
            [self performSegueWithIdentifier:@"PresentGraphLandscape" sender:self];
        });
    }
    else if (UIDeviceOrientationIsPortrait(deviceOrientation) && _isShowingLandscapeView) {
        if ( NO == [self.presentedViewController isKindOfClass:[RHCRotatingNavigationController class]] ) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
            self->_isShowingLandscapeView = NO;
        });
    }
}


- (void)beginObservingOrientation
{
    if ( self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ) {
        return;
    }

    _isShowingLandscapeView = NO;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


- (void)endObservingOrientation
{
    if ( self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad ) {
        return;
    }
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
        [userActivity becomeCurrent];
    }
}


- (void)saveActivity
{
    NSUserActivity *userActivity = self.userActivity;

    if (userActivity == nil) {
        userActivity = [[NSUserActivity alloc] initWithActivityType:[[NSBundle mainBundle] bundleIdentifier]];
        userActivity.delegate = self;
    }

    //[userActivity resignCurrent];

    userActivity.needsSave = YES;
    userActivity.eligibleForSearch = NO;
    userActivity.eligibleForHandoff = YES;
    userActivity.eligibleForPublicIndexing = NO;
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
    self.currentIndexPath = [NSIndexPath indexPathForRow:self.pageControl.currentPage inSection:0];
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
        NSInteger stationId = [identifier integerValue];

        CDStation *station = [CDStation existingStationWithId:stationId inManagedObjectContext:[self fetchedResultsController].managedObjectContext error:nil];
        if ( station ) {
            indexPath = [[self fetchedResultsController] indexPathForObject:station];
        }
    }
    return indexPath;
}



#pragma mark - WCSession update application context

- (void)updateApplicationContextToWatch
{
    WCSession *session = [WCSession defaultSession];

    if ( session.isPaired == NO || session.isWatchAppInstalled == NO ) {
        DLOG(@"Watch is not present: %d - %d", session.isPaired, session.isWatchAppInstalled);
        return;
    }

    NSArray *result = [CDStation visibleStationsInManagedObjectContext:[DataManager shared].viewContext limit:0];
    NSMutableArray *stations = [NSMutableArray array];

    for ( CDStation *station in result ) {
        NSDictionary *info = @{
                               @"stationId": station.stationId,
                               @"stationName": station.stationName,
                               @"order": station.order,
                               @"hidden": station.isHidden,
                               @"latitude": station.coordinateLat,
                               @"longitude": station.coordinateLon
                               };
        [stations addObject:info];
    }


    NSDictionary *context = @{
                              @"activeStations": stations,
                              @"unit": @([[AppConfig sharedConfiguration].applicationUserDefaults integerForKey:@"selectedUnit"])
                              };
    NSError *error = nil;

    if ( [session updateApplicationContext:context error: &error] == NO ) {
        DLOG(@"Failed: %@", error.localizedDescription);
    }
}


@end
