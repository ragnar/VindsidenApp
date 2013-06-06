//
//  VindsidenPlotClient.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 24.08.10.
//  Copyright 2010 Shortcut AS. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VindsidenPlotClient : NSObject <NSXMLParserDelegate>
{

    @private
    NSData *_data;
    NSString            *_xml;
    NSMutableArray      *_plots;
    NSMutableDictionary *_currentPlot;
    NSMutableString     *_currentString;
    BOOL                _isStoringCharacters;
    
}

- (instancetype)initWithXML:(NSString *)xml;
- (instancetype)initWithData:(NSData *)data;
- (NSArray *)parse;

@end
