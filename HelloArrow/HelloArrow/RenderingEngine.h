//
//  RenderingEngine.h
//  HelloArrow
//
//  Created by Derek Lyons on 3/4/13.
//  Copyright (c) 2013 Derek Lyons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface RenderingEngine : NSObject
@property (nonatomic, strong) EAGLContext *context;

- (id)initWithLayer:(CAEAGLLayer *)eaglLayer andViewportSize:(CGSize)size;

- (void)render;
- (void)updateAnimationWithTimestep:(float)timestep;
- (void)handleRotationToOrientation:(UIDeviceOrientation)orientation;

@end
