//
//  VindsidenStationClient.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 21.09.10.
//  Copyright 2010 Shortcut AS. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VindsidenStationClient : NSObject <NSXMLParserDelegate>
{

    @private
    NSData *_data;
    NSString            *_xml;
    NSMutableArray      *_stations;
    NSMutableDictionary *_currentStation;
    NSMutableString     *_currentString;
    BOOL                _isStoringCharacters;
    
    NSDateFormatter     *_dateFormatter;
    
}

@property (nonatomic, retain, readonly) NSDateFormatter *dateFormatter;

- (id)initWithXML:(NSString *)xml;
- (instancetype)initWithData:(NSData *)data;
- (NSArray *)parse;

@end
