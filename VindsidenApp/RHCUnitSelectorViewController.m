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


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)preferredContentSizeChanged:(NSNotification *)aNotification
{
    [self.view setNeedsLayout];
    [self.tableView reloadData];
}



#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
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


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.font = [UIFont preferredFontForTextStyle:[[cell.textLabel.font fontDescriptor] objectForKey:@"NSCTFontUIUsageAttribute"]];
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:[[cell.detailTextLabel.font fontDescriptor] objectForKey:@"NSCTFontUIUsageAttribute"]];
}

@end
