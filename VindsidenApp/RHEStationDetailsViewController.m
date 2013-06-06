//
//  RHEStationDetailsViewController.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 16.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import "RHEStationDetailsViewController.h"
#import "CDStation.h"


@interface RHEStationDetailsViewController ()

@property (strong, nonatomic) NSRegularExpression *regexRemoveHTMLTags;

@end

@implementation RHEStationDetailsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = self.station.stationName;
    
    self.cameraButton.hidden = ( [self.station.webCamImage length] <= 0 );
}


- (void)viewDidUnload
{
    [self setCameraButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowWebCam"]) {
        [TestFlight passCheckpoint:@"show web cam from details"];

        RHEWebCamViewController *controller = segue.destinationViewController;
        controller.navigationItem.leftBarButtonItem = nil;
        controller.webCamURL = [NSURL URLWithString:self.station.webCamImage];
        controller.stationName = self.station.stationName;
        controller.permitText = self.station.webCamText;
        controller.delegate = self;
    }
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StationDetailsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    switch ( indexPath.row )
    {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Name", nil);
            cell.detailTextLabel.text = _station.stationName;
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"Place", nil);
            cell.detailTextLabel.text = _station.city;
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"Copyright", nil);
            cell.detailTextLabel.text = _station.copyright;
            break;
        case 3:
            cell.textLabel.text = NSLocalizedString(@"Info", nil);
            cell.detailTextLabel.text = [[self regexRemoveHTMLTags] stringByReplacingMatchesInString:_station.stationText
                                                                                             options:0
                                                                                               range:NSMakeRange(0, [_station.stationText length])
                                                                                        withTemplate:@""];
            break;
        case 4:
            cell.textLabel.text = NSLocalizedString(@"Status", nil);
            cell.detailTextLabel.text = [[self regexRemoveHTMLTags] stringByReplacingMatchesInString:_station.statusMessage
                                                                                             options:0
                                                                                               range:NSMakeRange(0, [_station.statusMessage length])
                                                                                        withTemplate:@""];
            break;
        case 5:
            cell.textLabel.text = NSLocalizedString(@"Camera", nil);
            cell.detailTextLabel.text = [[self regexRemoveHTMLTags] stringByReplacingMatchesInString:_station.webCamText
                                                                                             options:0
                                                                                               range:NSMakeRange(0, [_station.webCamText length])
                                                                                        withTemplate:@""];
            break;
    }
}


- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = CGSizeMake( 0.0, 0.0);

    switch ( indexPath.row )
    {
        case 0:
            size = [_station.stationName sizeWithFont:[UIFont boldSystemFontOfSize:15.0]
                                    constrainedToSize:CGSizeMake( 207.0, 400.0)];
            break;
        case 1:
            size = [_station.city sizeWithFont:[UIFont boldSystemFontOfSize:15.0]
                             constrainedToSize:CGSizeMake( 207.0, 400.0)];
            break;
        case 2:
            size = [_station.copyright sizeWithFont:[UIFont boldSystemFontOfSize:15.0]
                                  constrainedToSize:CGSizeMake( 207.0, 400.0)];
            break;
        case 3:
            size = [[[self regexRemoveHTMLTags] stringByReplacingMatchesInString:_station.stationText
                                                                         options:0
                                                                           range:NSMakeRange(0, [_station.stationText length])
                                                                    withTemplate:@""]
                    sizeWithFont:[UIFont boldSystemFontOfSize:15.0]
                    constrainedToSize:CGSizeMake( 207.0, 400.0)];
            size.height += 4;
            break;
        case 4:
            size = [_station.statusMessage sizeWithFont:[UIFont boldSystemFontOfSize:15.0]
                                      constrainedToSize:CGSizeMake( 207.0, 400.0)];
            break;
        case 5:
            if ( [_station.webCamText length] > 0 ) {
                size = [[[self regexRemoveHTMLTags] stringByReplacingMatchesInString:_station.webCamText
                                                                             options:0
                                                                               range:NSMakeRange(0, [_station.webCamText length])
                                                                        withTemplate:@""]
                        sizeWithFont:[UIFont boldSystemFontOfSize:15.0]
                        constrainedToSize:CGSizeMake( 207.0, 400.0)];
                size.height += 4;
            }
            break;
    }

    return MAX( 50.0, size.height);
}



#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.row == 1 ) {
        [self showMap:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -


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


#pragma mark - Actions


- (void)done:(id)sender
{
    [_delegate rheStationDetailsViewControllerDidFinish:self];
}


- (IBAction)gotoYR:(id)sender
{
    [TestFlight passCheckpoint:@"goto yr"];

    NSURL *url = [NSURL URLWithString:[_station.yrURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:url];
}


- (IBAction)showMap:(id)sender
{
    [TestFlight passCheckpoint:@"show map"];

    CLLocationCoordinate2D spotCord = CLLocationCoordinate2DMake( [_station.coordinateLat doubleValue], [_station.coordinateLon doubleValue]);
    
    NSMutableString *query = [NSMutableString stringWithString:@"http://maps.google.com/maps?t=h&z=10"];
    
    if ( spotCord.latitude > 0 || spotCord.longitude > 0 ) {
        [query appendFormat:@"&ll=%f,%f", spotCord.latitude, spotCord.longitude];
    }
    
    if ( [_station.city length] > 0 ) {
        [query appendFormat:@"&q=%@", _station.city];
    } else {
        [query appendFormat:@"&q=%@", _station.stationName];
    }
    
    NSURL *url = [NSURL URLWithString:[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:url];
}


#pragma mark - WebCamImage Delegate


- (void)rheWebCamViewDidFinish:(RHEWebCamViewController *)controller
{
    [self.navigationController popViewControllerAnimated:YES];
}


@end
