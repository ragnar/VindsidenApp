//
//  VindsidenPlotClient.m
//  Vindsiden
//
//  Created by Ragnar Henriksen on 24.08.10.
//  Copyright 2010 Shortcut AS. All rights reserved.
//

#import "VindsidenPlotClient.h"


@implementation VindsidenPlotClient

- (instancetype)initWithXML:(NSString *)xml
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
    _plots = [[NSMutableArray alloc] initWithCapacity:0];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:_data];
    [parser setDelegate:self];
    BOOL success = [parser parse];
    
    
    if (!success) {
        DLOG(@"not a success");
        return nil;
    }
    
    DLOG(@"Parsing complete. %d plots found", [_plots count]);
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"Time" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1];
    NSArray *sorted = [_plots sortedArrayUsingDescriptors:sortDescriptors];

    return sorted;
}

#pragma mark -
#pragma mark NSXMLParser Delegates

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ( [elementName isEqualToString:@"Measurement"] ) {
        _currentPlot = [[NSMutableDictionary alloc] initWithCapacity:5];
    } else if ([elementName isEqualToString:@"Time"] ||
               [elementName isEqualToString:@"WindAvg"] ||
               [elementName isEqualToString:@"WindMax"] ||
               [elementName isEqualToString:@"WindMin"] ||
               [elementName isEqualToString:@"DirectionAvg"] ||
               [elementName isEqualToString:@"Temperature1"])
    {
        _currentString = [[NSMutableString alloc] initWithCapacity:0];
        _isStoringCharacters = YES;
    }
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"Measurement"]) {
        [_plots addObject:_currentPlot];
    } else if ([elementName isEqualToString:@"Time"]) {
        _currentPlot[@"plotTime"] = _currentString;
    } else if ([elementName isEqualToString:@"WindAvg"]) {
        _currentPlot[@"windAvg"] = @([_currentString doubleValue]);
    } else if ([elementName isEqualToString:@"WindMax"]) {
        _currentPlot[@"windMax"] = @([_currentString doubleValue]);
    } else if ( [elementName isEqualToString:@"WindMin"]) {
        _currentPlot[@"windMin"] = @([_currentString doubleValue]);
    } else if ( [elementName isEqualToString:@"DirectionAvg"]) {
        _currentPlot[@"windDir"] = _currentString;
    } else if ( [elementName isEqualToString:@"Temperature1"]) {
        _currentPlot[@"tempAir"] = _currentString;
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
