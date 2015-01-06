//
//  VindsidenPlotClient.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 24.08.10.
//  Copyright 2010 Shortcut AS. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VindsidenPlotClient : NSObject <NSXMLParserDelegate>

- (instancetype)initWithXML:(NSString *)xml;
- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithParser:(NSXMLParser *)parser;

- (NSArray *)parse;

@end
