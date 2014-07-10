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

@import VindsidenKit;

@implementation VindsidenStationClient
{
    NSData *_data;
    NSString            *_xml;
    NSMutableArray      *_stations;
    NSMutableDictionary *_currentStation;
    NSMutableString     *_currentString;
    BOOL                _isStoringCharacters;

    NSDateFormatter     *_dateFormatter;
    NSXMLParser         *_parser;
}


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


- (instancetype)initWithParser:(NSXMLParser *)parser
{
    self = [super init];

    if ( self ) {
        _parser = parser;
        _isStoringCharacters = NO;
    }

    return self;
}


- (NSArray *)parse
{
    _stations = [[NSMutableArray alloc] initWithCapacity:0];

    if ( nil == _parser ) {
        _parser = [[NSXMLParser alloc] initWithData:_data];
    }

    [_parser setDelegate:self];
    BOOL success = [_parser parse];

    if (!success) {
        DLOG(@"not a success");
        return nil;
    }

    DLOG(@"Parsing complete. %ld stations found", (unsigned long)[_stations count]);
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"stationId" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor1];
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
        _currentStation[@"stationId"] = @([_currentString doubleValue]);
    } else if ([elementName isEqualToString:@"Name"]) {
        _currentStation[@"stationName"] = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ([elementName isEqualToString:@"Latitude"]) {
        _currentStation[@"coordinateLat"] = @([_currentString doubleValue]);
    } else if ( [elementName isEqualToString:@"Longitude"]) {
        _currentStation[@"coordinateLon"] = @([_currentString doubleValue]);
    } else if ( [elementName isEqualToString:@"MeteogramUrl"]) {
        _currentStation[@"yrURL"] = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ( [elementName isEqualToString:@"Text"]) {
        _currentStation[@"stationText"] = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ( [elementName isEqualToString:@"Copyright"]) {
        _currentStation[@"copyright"] = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ( [elementName isEqualToString:@"StatusMessage"]) {
        _currentStation[@"statusMessage"] = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ( [elementName isEqualToString:@"LastMeasurementTime"]) {
        NSString *dateString = [_currentString fixDateString];
        _currentStation[@"lastMeasurement"] = [[Datamanager sharedManager] dateFromString:dateString];
    } else if ( [elementName isEqualToString:@"City"]) {
        _currentStation[@"city"] = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ( [elementName isEqualToString:@"WebcamImage"]) {
        _currentStation[@"webCamImage"] = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if ( [elementName isEqualToString:@"WebcamText"]) {
        _currentStation[@"webCamText"] = _currentString;
    } else if ( [elementName isEqualToString:@"WebcamUrl"]) {
        _currentStation[@"webCamURL"] = [_currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
