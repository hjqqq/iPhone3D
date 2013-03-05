//
//  GLView.m
//  HelloArrow
//
//  Created by Derek Lyons on 3/4/13.
//  Copyright (c) 2013 Derek Lyons. All rights reserved.
//

#import "GLView.h"

@implementation GLView

#pragma mark - Setup

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Create a GL-friendly layer and set it to opaque.
        // (This tells Quartz that we don't need it to handle transparency for this layer).
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)super.layer;
        [eaglLayer setOpaque:YES];
        
        // Create our OpenGL context and make it current.
        BOOL contextSetupSucceeded = NO;
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (self.context) {
            
            // After this call, any further OpenGL calls in this thread will be directed
            // to this context.
            contextSetupSucceeded = [EAGLContext setCurrentContext:self.context];
        }
        
        if (!contextSetupSucceeded) {
            NSLog(@"Setup of the EAGLContext did not succeed.");
            return nil;
        }
        
        //
        // OpenGL initialization
        //
        
        // OpenGL uses GLuints (just unsigned ints) to represent many of the objects that
        // it manages.
        GLuint framebuffer, renderbuffer;
        
        // Renderbuffer: 2D surface filled with data of a particular kind (in our case, color)
        glGenRenderbuffers(1, &renderbuffer);
        
        // Framebuffer: A bundle of renderbuffers.
        glGenFramebuffers(1, &framebuffer);
        
        // Bind our buffers to the OpenGL pipeline. Binding allows subsequent OpenGL calls
        // to interact with these objects.
        glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        // Allocate storage for the renderbuffer in our graphics context.
        [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
        
        // Attach the framebuffer to the renderbuffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
        
        glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
        
        [self renderView];
    }
    
    return self;
}

- (void)renderView
{
    glClearColor(0.5f, 0.5f, 0.5f, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Rather than drawing directly to the screen, most OpenGL programs render to a buffer
    // that is then atomically presented to the screen.
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}


#pragma mark - Teardown

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    self.context = nil;
}

@end
