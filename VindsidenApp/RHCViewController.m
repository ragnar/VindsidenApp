//
//  RHCViewController.m
//  Vindsiden-v2
//
//  Created by Ragnar Henriksen on 01.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "RHCViewController.h"
#import "RHCStationCell.h"
#import "CDStation.h"
#import "RHEStationDetailsViewController.h"

#import "RHEVindsidenAPIClient.h"

static NSString *kCellID = @"stationCellID";

@interface RHCViewController ()

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) UIButton *cameraButton;
@property (weak, nonatomic) UIPageControl *pageControl;

@end


@implementation RHCViewController
{
    NSMutableSet *_transformedCells;
    BOOL __block _fetchingImage;
    BOOL _wasVisible;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIToolbar *toolbar = [UIToolbar new];
    toolbar.barStyle = UIBarStyleDefault;

    // size up the toolbar and set its frame
    [toolbar sizeToFit];
    CGFloat toolbarHeight = CGRectGetHeight([toolbar frame]);
    //CGRect mainViewBounds = self.view.bounds;
    CGRect mainViewBounds = [[UIApplication sharedApplication].delegate window].bounds;
    [toolbar setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
                                 CGRectGetMinY(mainViewBounds) + CGRectGetHeight(mainViewBounds) - (toolbarHeight * 1.0),
                                 CGRectGetWidth(mainViewBounds),
                                 toolbarHeight)];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake( 0.0, 0.0, 33.0, 33.0);
    [button addTarget:self action:@selector(settings:) forControlEvents:UIControlEventTouchUpInside];
    //[button setImage:[[UIImage imageNamed:@"icon_toolbar_settings21x21"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"icon_toolbar_settings21x21"] forState:UIControlStateNormal];
    UIBarButtonItem *bb = [[UIBarButtonItem alloc] initWithCustomView:button];

    button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    //button.frame = CGRectMake( 0.0, 0.0, 33.0, 33.0);
    [button addTarget:self action:@selector(info:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *bc = [[UIBarButtonItem alloc] initWithCustomView:button];

    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake( 0.0, 0.0, 44.0, 33.0);
    [button addTarget:self action:@selector(camera:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *bt = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.cameraButton = button;

    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolbar setItems:@[bb, flex, bt,flex, bc]];
    [self.view addSubview:toolbar];


    UIPageControl *pControl = [UIPageControl new];
    pControl.frame = CGRectMake(CGRectGetMinX(mainViewBounds),
                                CGRectGetMinY(mainViewBounds) + CGRectGetHeight(mainViewBounds) - (toolbarHeight + 16.0),
                                CGRectGetWidth(mainViewBounds),
                                16.0);
    pControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
    pControl.numberOfPages = [CDStation numberOfVisibleStations];

    [pControl addTarget:self action:@selector(pageControlChangedValue:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:pControl];
    self.pageControl = pControl;

    _transformedCells = [NSMutableSet set];

    [[RHEVindsidenAPIClient defaultManager] fetchStations:^(BOOL success, NSArray *stations) {
        if ( success ) {
            [self updateStations:stations];
            [self updateCameraButton:YES];
        }
    }
                                                    error:^(NSError *error) {
                                                        [[RHCAlertManager defaultManager] showNetworkError:error];
                                                    }
     ];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
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


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    RHCStationCell *cell = [self.collectionView visibleCells][0];

    if ( [segue.identifier isEqualToString:@"ShowSettings"] ) {
        UINavigationController *navCon = segue.destinationViewController;
        RHCSettingsViewController *controller = navCon.viewControllers[0];
        controller.delegate = self;
    } else if ( [segue.identifier isEqualToString:@"ShowStationDetails"] ) {
        UINavigationController *navCon = segue.destinationViewController;
        RHEStationDetailsViewController *controller = navCon.viewControllers[0];
        controller.delegate = self;
        controller.station = cell.currentStation;
    } else if ([segue.identifier isEqualToString:@"ShowWebCam"]) {
		UINavigationController *navigationController = segue.destinationViewController;
		RHEWebCamViewController *controller = navigationController.viewControllers[0];
        [controller.navigationController.navigationBar setTintColor:nil];
        controller.webCamURL = [NSURL URLWithString:cell.currentStation.webCamImage];
        controller.stationName = cell.currentStation.stationName;
        controller.permitText = cell.currentStation.webCamText;
        controller.delegate = self;
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


#pragma mark - CollectionView Delegate


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsController] sections] objectAtIndex:0];
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
    if ( CGRectGetHeight(collectionView.bounds) > 460.0) {
        return CGSizeMake( 320.0, 524.0);
    }
    return CGSizeMake( 320.0, 436.0);
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets ei = [(UICollectionViewFlowLayout *)collectionViewLayout sectionInset];
    ei.bottom = 44.0;
    return ei;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ( scrollView != self.collectionView ) {
        return;
    }

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
    [self updateCameraButton:NO];
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
                             [[NSUserDefaults standardUserDefaults] setObject:@(indexPath.row) forKey:@"selectedIndexPath"];
                             [[NSUserDefaults standardUserDefaults] synchronize];
                             [self updateCameraButton:YES];
                             self.pageControl.currentPage = indexPath.row;
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

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSString *cacheName = @"StationList";

    NSManagedObjectContext *context = [(id)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDStation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isHidden == NO"];
    fetchRequest.predicate = predicate;

    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor1, nil];
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
            break;
        case NSFetchedResultsChangeUpdate:
            break;
    }
}


- (void)updateStations:(NSArray *)stations
{
    [CDStation updateStations:stations];

    if ( [stations count] > 0 ) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUpdated"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


- (void)updateCameraButton:(BOOL)update
{
    if ( _fetchingImage ) {
        return;
    }

    if ( [[self.collectionView visibleCells] count] == 0 ) {
        return;
    }

    RHCStationCell *cell = [self.collectionView visibleCells][0];

    
    if ( [cell.currentStation.webCamImage length] == 0 ) {
        return;
    }
    _fetchingImage = YES;

    [UIView animateWithDuration:0.25
                     animations:^{
                         self.cameraButton.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         if ( update ) {
                             [[RHEVindsidenAPIClient defaultManager] fetchWebCamImageForURL:[NSURL URLWithString:cell.currentStation.webCamImage]
                                                                           ignoreFetchLimit:YES
                                                                                    success:^(UIImage *image) {
                                                                                        [UIView animateWithDuration:0.2
                                                                                                         animations:^{
                                                                                                             self.cameraButton.layer.shadowColor = [[UIColor blackColor] CGColor];
                                                                                                             self.cameraButton.layer.shadowOffset = CGSizeMake( 1, 2);
                                                                                                             self.cameraButton.layer.shadowOpacity = 0.75;
                                                                                                             self.cameraButton.layer.shadowRadius = 2.5;
                                                                                                             self.cameraButton.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.cameraButton.bounds].CGPath;
                                                                                                             self.cameraButton.alpha = 1.0;
                                                                                                             [self.cameraButton setImage:image forState:UIControlStateNormal];
                                                                                                         }
                                                                                                         completion:^(BOOL finished) {
                                                                                                             _fetchingImage = NO;
                                                                                                         }
                                                                                         ];
                                                                                    }
                                                                                    failure:^(NSError *error) {
                                                                                        [UIView animateWithDuration:0.2
                                                                                                         animations:^{
                                                                                                             self.cameraButton.alpha = 0.0;
                                                                                                         }
                                                                                                         completion:^(BOOL finished) {
                                                                                                             _fetchingImage = NO;
                                                                                                         }
                                                                                         ];
                                                                                    }
                              ];
                         } else {
                             _fetchingImage = NO;
                         }
                     }
     ];
}


#pragma mark - Actions


- (IBAction)settings:(id)sender
{
    [TestFlight passCheckpoint:@"show settings"];
    [self performSegueWithIdentifier:@"ShowSettings" sender:sender];
}


- (IBAction)info:(id)sender
{
    [TestFlight passCheckpoint:@"show info"];
    [self performSegueWithIdentifier:@"ShowStationDetails" sender:sender];
}


- (IBAction)camera:(id)sender
{
    [TestFlight passCheckpoint:@"show camera"];
    [self performSegueWithIdentifier:@"ShowWebCam" sender:sender];
}


- (IBAction)pageControlChangedValue:(id)sender
{
    [TestFlight passCheckpoint:@"changed page"];
    NSInteger page = [(UIPageControl *)sender currentPage];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:page inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}


#pragma mark - Station Details Delegate


- (void)rheStationDetailsViewControllerDidFinish:(RHEStationDetailsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - WebCam Delegate


- (void)rheWebCamViewDidFinish:(RHEWebCamViewController *)controller
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


@end
