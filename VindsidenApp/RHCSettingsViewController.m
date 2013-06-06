//
//  RHCSettingsViewController.m
//  VindsidenApp
//
//  Created by Ragnar Henriksen on 04.05.13.
//  Copyright (c) 2013 RHC. All rights reserved.
//

#import "RHCSettingsViewController.h"
#import "NSNumber+Convertion.h"
#import "CDStation.h"

@interface RHCSettingsViewController ()

- (IBAction)done:(id)sender;

@end


@implementation RHCSettingsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
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
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...

    if ( indexPath.row == 0 ) {
        cell.textLabel.text = NSLocalizedString(@"Stations", nil);
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [CDStation numberOfVisibleStations]];
    } else {
        SpeedConvertion unit = [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedUnit"];
        cell.textLabel.text = NSLocalizedString(@"Units", nil);
        cell.detailTextLabel.text = [NSNumber shortUnitNameString:unit];
    }
    
    return cell;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectZero];
    NSString *v = [NSString stringWithFormat:NSLocalizedString(@"%@ version %@", @"Version string in settings view"),
                   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                   [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] stringByAppendingFormat:@".%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]];

    tv.text = [NSLocalizedString(@"LABEL_PERMIT", @"Værdata hentet med tillatelse fra\nhttp://vindsiden.no\n\n") stringByAppendingString:v];
    tv.editable = NO;
    tv.textAlignment = NSTextAlignmentCenter;
    tv.backgroundColor = [UIColor clearColor];
    tv.dataDetectorTypes = UIDataDetectorTypeLink;
    tv.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
    tv.textColor = [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1.0];
    tv.layer.shadowColor = [[UIColor whiteColor] CGColor];
    tv.layer.shadowOffset = CGSizeMake( 0.0f, 1.0f);
    tv.layer.shadowOpacity = 1.0f;
    tv.layer.shadowRadius = 1.0f;
    [tv sizeToFit];
    return tv;

}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 100.0;
}


#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.row == 0 ) {
        [TestFlight passCheckpoint:@"show station picker"];
        [self performSegueWithIdentifier:@"ShowStationPicker" sender:self];
    } else {
        [TestFlight passCheckpoint:@"show unit selector"];
        [self performSegueWithIdentifier:@"ShowUnitSelector" sender:self];
    }
}


#pragma mark - Actions


- (IBAction)done:(id)sender
{
    if ( [self.delegate respondsToSelector:@selector(rhcSettingsDidFinish:)] ) {
        [self.delegate rhcSettingsDidFinish:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


@end
