//
//  RHEGraphView.h
//  Vindsiden
//
//  Created by Ragnar Henriksen on 16.05.12.
//  Copyright (c) 2012 Shortcut AS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RHEGraphView : UIView

@property (copy, nonatomic) NSArray *plots;
@property (copy, nonatomic) NSString *copyright;

- (void) viewIsUpdated;


@end
