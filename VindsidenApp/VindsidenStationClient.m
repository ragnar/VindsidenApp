//
//  VindsidenStationClient.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 21.09.10.
//  Copyright 2010 Shortcut AS. All rights reserved.
//

#import "RHCAppDelegate.h"
#import "VindsidenStationClient.h"
#import "NSString+fixDateString.h"

@implementation VindsidenStationClient

- (id) initWithXML:(NSString *)xml
{
    if ( (self = [super init]) ) {
        _data = [_xml dataUsingEncoding:NSISOLatin1StringEncoding];
        _isStoringCharacters = NO;
    }

    return self;
}


- (instancetype)initWithData:(NSData *)data
{
    if ( (self = [super init]) ) {
        _data = [data copy];
        _isStoringCharacters = NO;
    }

    return self;
}


- (NSArray *) parse
{
    _stations = [[NSMutableArray alloc] initWithCapacity:0];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:_data];
    [parser setDelegate:self];
    BOOL success = [parser parse];

    if (!success) {
        DLOG(@"not a success");
        return nil;
    }

    DLOG(@"Parsing complete. %d stations found", [_stations count]);
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"stationId" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor1, nil];
    NSArray *sorted = [_stations sortedArrayUsingDescriptors:sortDescriptors];

    return sorted;
}

#pragma mark -
#pragma mark NSXMLParser Delegates

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ( [elementName isEqualToString:@"Station"] ) {
        _currentStation = [[NSMutableDictionary alloc] initWithCapacity:5];
    } else if ([elementName isEqualToString:@"StationID"] ||
               [elementName isEqualToString:@"Name"] ||
               [elementName isEqualToString:@"Text"] ||
               [elementName isEqualToString:@"MeteogramUrl"] ||
               [elementName isEqualToString:@"Latitude"] ||
               [elementName isEqualToString:@"Longitude"] ||
               [elementName isEqualToString:@"Copyright"] ||
               [elementName isEqualToString:@"LastMeasurementTime"] ||
               [elementName isEqualToString:@"StatusMessage"] ||
               [elementName isEqualToString:@"City"] ||
               [elementName isEqualToString:@"WebcamImage"] ||
               [elementName isEqualToString:@"WebcamText"] ||
               [elementName isEqualToString:@"WebcamUrl"] )
    {
        _currentString = [[NSMutableString alloc] initWithCapacity:0];
        _isStoringCharacters = YES;
    }
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"Station"]) {
        [_stations addObject:_currentStation];
    } else if ([elementName isEqualToString:@"StationID"]) {
        [_currentStation setObject:[NSNumber numberWithDouble:[_currentString doubleValue]] forKey:@"stationId"];
    } else if ([elementName isEqualToString:@"Name"]) {
        [_currentStation setObject:[_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                            forKey:@"stationName"];
    } else if ([elementName isEqualToString:@"Latitude"]) {
        [_currentStation setObject:[NSNumber numberWithDouble:[_currentString doubleValue]] forKey:@"coordinateLat"];
    } else if ( [elementName isEqualToString:@"Longitude"]) {
        [_currentStation setObject:[NSNumber numberWithDouble:[_currentString doubleValue]] forKey:@"coordinateLon"];
    } else if ( [elementName isEqualToString:@"MeteogramUrl"]) {
        [_currentStation setObject:[_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                            forKey:@"yrURL"];
    } else if ( [elementName isEqualToString:@"Text"]) {
        [_currentStation setObject:[_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                            forKey:@"stationText"];
    } else if ( [elementName isEqualToString:@"Copyright"]) {
        [_currentStation setObject:[_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                            forKey:@"copyright"];
    } else if ( [elementName isEqualToString:@"StatusMessage"]) {
        [_currentStation setObject:[_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                            forKey:@"statusMessage"];
    } else if ( [elementName isEqualToString:@"LastMeasurementTime"]) {
        RHCAppDelegate *_appDelegate = [[UIApplication sharedApplication] delegate];
        NSString *dateString = [_currentString fixDateString];
        NSDate *date = [_appDelegate dateFromString:dateString];
        [_currentStation setObject:date forKey:@"lastMeasurement"];
    } else if ( [elementName isEqualToString:@"City"]) {
        [_currentStation setObject:[_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                            forKey:@"city"];
    } else if ( [elementName isEqualToString:@"WebcamImage"]) {
        [_currentStation setObject:[_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                            forKey:@"webCamImage"];
    } else if ( [elementName isEqualToString:@"WebcamText"]) {
        [_currentStation setObject:_currentString forKey:@"webCamText"];
    } else if ( [elementName isEqualToString:@"WebcamUrl"]) {
        [_currentStation setObject:[_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                            forKey:@"webCamURL"];
    }

    _isStoringCharacters = NO;
}



- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if ( _isStoringCharacters ) {
        [_currentString appendString:string];
    }
}


@end
