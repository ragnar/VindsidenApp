//
//  VindsidenStationClient.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 21.09.10.
//  Copyright 2010 Shortcut AS. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VindsidenStationClient : NSObject <NSXMLParserDelegate>

@property (nonatomic, retain, readonly) NSDateFormatter *dateFormatter;

- (instancetype)initWithXML:(NSString *)xml;
- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithParser:(NSXMLParser *)parser;

- (NSArray *)parse;

@end
