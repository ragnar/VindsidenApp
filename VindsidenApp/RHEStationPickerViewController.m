//
//  RHEStationPickerViewController.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 14.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import "RHCAppDelegate.h"
#import "RHEStationPickerViewController.h"
#import "RHEVindsidenAPIClient.h"
#import "CDStation.h"

@import VindsidenKit;

@interface RHEStationPickerViewController ()

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (assign, nonatomic) BOOL changeIsUserDriven;
@end

@implementation RHEStationPickerViewController
{
    BOOL _indexOffset;
}

@synthesize delegate = _delegate;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize changeIsUserDriven = _changeIsUserDriven;


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[[RHEVindsidenAPIClient defaultManager] operationQueue] setSuspended:YES];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[[RHEVindsidenAPIClient defaultManager] operationQueue] setSuspended:NO];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.navigationItem.leftBarButtonItem.enabled = !editing;
}


- (void)preferredContentSizeChanged:(NSNotification *)aNotification
{
    [self.tableView reloadData];
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    @try {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self fetchedResultsController] sections][section];
        return [sectionInfo numberOfObjects];
    }
    @catch (NSException *exception) {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    CDStation *station = (CDStation *)[[self fetchedResultsController] objectAtIndexPath:indexPath];

    cell.textLabel.text = station.stationName;
    cell.detailTextLabel.text = station.city;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if ( fromIndexPath == toIndexPath ) {
        return;
    }

    _changeIsUserDriven = YES;

    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];

    NSMutableArray *arr = [NSMutableArray arrayWithArray:[[self.fetchedResultsController fetchedObjects] sortedArrayUsingComparator:^NSComparisonResult(CDStation *obj1, CDStation *obj2) {
        return [obj1.order compare:obj2.order];
    }]];
    CDStation *objToMove = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];

    objToMove.isHidden = @(toIndexPath.section == 1);

    [arr removeObject:objToMove];
    [arr insertObject:objToMove atIndex:toIndexPath.row];

    int iVisible = 100;
    int iHidden = 200;
    for ( CDStation *station in arr ) {
        if ( [station.isHidden boolValue] ) {
            station.order = @(++iHidden);
        } else {
            station.order = @(++iVisible);
        }
    }

    NSError *error = NULL;
    if (![context save:&error]) {
        DLOG(@"%@", error);
    }
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}


- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if ( sourceIndexPath.section == 1 ) {
        return proposedDestinationIndexPath;
    }

    NSInteger rows = [self tableView:self.tableView numberOfRowsInSection:sourceIndexPath.section];
    if ( rows <= 1 ) {
        return sourceIndexPath;
    }
    return proposedDestinationIndexPath;
}


#pragma mark - Table view delegate


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( section == 0 ) {
        return NSLocalizedString(@"Visible", nil);
    }
    return NSLocalizedString(@"Not Visible", nil);
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.font = [UIFont preferredFontForTextStyle:[[cell.textLabel.font fontDescriptor] objectForKey:@"NSCTFontUIUsageAttribute"]];
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:[[cell.detailTextLabel.font fontDescriptor] objectForKey:@"NSCTFontUIUsageAttribute"]];
}


#pragma mark - Fetched results controller


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if ( !_changeIsUserDriven ) {
        [self.tableView beginUpdates];
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{

    if ( _changeIsUserDriven ) {
        return;
    }

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{

    if ( _changeIsUserDriven ) {
        return;
    }

    UITableView *tableView = self.tableView;

    switch(type) {

        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationTop];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationTop];
            break;

        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;

        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ( !_changeIsUserDriven ) {
        [self.tableView endUpdates];
    } else if ( !self.tableView.editing) {
        [self.tableView reloadData];
    }
    _changeIsUserDriven = NO;
}


- (NSFetchedResultsController *) fetchedResultsController
{
    if ( _fetchedResultsController != nil ) {
        return _fetchedResultsController;
    }

    NSManagedObjectContext *context = [[Datamanager sharedManager] managedObjectContext];
    NSString *cacheName = @"StationPicker";
    [NSFetchedResultsController deleteCacheWithName:cacheName];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CDStation" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:context
                                                                                                  sectionNameKeyPath:@"isHidden"
                                                                                                           cacheName:cacheName];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;

    NSError *error = nil;
    if ( ! [_fetchedResultsController performFetch:&error]) {
        WARNING(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _fetchedResultsController;
}


#pragma mark - Actions


- (IBAction)done:(id)sender
{
   // [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate rheStationPickerDidFinish:self];
}


@end
