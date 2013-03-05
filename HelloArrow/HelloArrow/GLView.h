//
//  GLView.h
//  HelloArrow
//
//  Created by Derek Lyons on 3/4/13.
//  Copyright (c) 2013 Derek Lyons. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RenderingEngine.h"

@interface GLView : UIView
@property (nonatomic, strong) RenderingEngine *renderingEngine;
@property (nonatomic) float timestamp;

- (void)renderView:(CADisplayLink *)displayLink;
- (void)deviceDidRotate:(NSNotification *)notification;

@end
