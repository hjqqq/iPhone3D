//
//  GLView.m
//  HelloArrow
//
//  Created by Derek Lyons on 3/4/13.
//  Copyright (c) 2013 Derek Lyons. All rights reserved.
//

#import "GLView.h"
#import <QuartzCore/QuartzCore.h>

@interface GLView()
@property (nonatomic, strong) CADisplayLink *displayLink;
@end

@implementation GLView

#pragma mark - Setup

+ (Class)layerClass
{
    // We override the layerClass method to return an OpenGL friendly layer.
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Create the rendering engine
        CAEAGLLayer *layer = (CAEAGLLayer *)super.layer;
        self.renderingEngine = [[RenderingEngine alloc] initWithLayer:layer andViewportSize:self.bounds.size];
        
        // Setup a displayLink to invoke renderView: every time the view refreshes.
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderView:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        
        // Register for device orientation notifications
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceDidRotate:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
        self.timestamp = CACurrentMediaTime();

        // Kickoff rendering
        [self renderView:nil];
    }
    
    return self;
}

- (void)renderView:(CADisplayLink *)displayLink
{
    if (displayLink != nil) {
        float elapsedSeconds = displayLink.timestamp - self.timestamp;
        self.timestamp = displayLink.timestamp;
        
        [self.renderingEngine updateAnimationWithTimestep:elapsedSeconds];
    }
    
    [self.renderingEngine render];
    
    // Rather than drawing directly to the screen, most OpenGL programs render to a buffer
    // that is then atomically presented to the screen.
    [self.renderingEngine.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)deviceDidRotate:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    [self.renderingEngine handleRotationToOrientation:orientation];
    [self renderView:nil];
}


#pragma mark - Teardown

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.displayLink invalidate];
    
    self.renderingEngine = nil;
    self.displayLink = nil;
}

@end
