//
//  RHCUnitSelectorViewController.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 04.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "RHCUnitSelectorViewController.h"
#import "NSNumber+Convertion.h"


@interface RHCUnitSelectorViewController ()

@end


@implementation RHCUnitSelectorViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UnitCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Configure the cell...
    cell.textLabel.text = [NSNumber longUnitNameString:indexPath.row+1];
    if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedUnit"] == indexPath.row+1 ) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Choose unit", nil);
}


#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSUserDefaults standardUserDefaults] setInteger:indexPath.row+1 forKey:@"selectedUnit"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [tableView reloadData];
}

@end
