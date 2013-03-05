//
//  RenderingEngine.m
//  HelloArrow
//
//  Created by Derek Lyons on 3/4/13.
//  Copyright (c) 2013 Derek Lyons. All rights reserved.
//

#import "RenderingEngine.h"

#define SHADER_EXTENSION        @"glsl"
#define ROTATION_RPM            1.0

typedef struct {
    float position[2];
    float color[4];
} Vertex;

const Vertex Vertices[] = {
    {{-0.5, -0.866}, {1.0, 1.0, 0.5, 1.0}},
    {{0.5, -0.866}, {1.0, 1.0, 0.5, 1.0}},
    {{0.0, 1.0}, {1.0, 1.0, 0.5, 1.0}},
    {{-0.5, -0.866}, {0.5, 0.5, 0.5, 1.0}},
    {{0.5, -0.866}, {0.5, 0.5, 0.5, 1.0}},
    {{0.0, -0.4}, {0.5, 0.5, 0.5, 1.0}}
};

@interface RenderingEngine()
@property (nonatomic) float currentRotationAngle;
@property (nonatomic) float desiredRotationAngle;

@property (nonatomic) GLuint simpleProgram;
@property (nonatomic) GLuint framebuffer;
@property (nonatomic) GLuint renderbuffer;

- (GLuint)buildProgramWithVertexShaderName:(NSString *)vertexShaderName
                     andFragmentShaderName:(NSString *)fragmentShaderName;

- (GLuint)compileShaderWithName:(NSString *)shaderName andType:(GLenum)shaderType;

- (void)applyOrthoWithMaxX:(float)maxX andMaxY:(float)maxY;
- (void)applyRotation:(float)degrees;

@end

@implementation RenderingEngine

- (id)initWithLayer:(CAEAGLLayer *)eaglLayer andViewportSize:(CGSize)size
{
    self = [super init];
    if (self) {
        
        // Set the eaglLayer to opaque.
        // (This tells Quartz that we don't need it to handle transparency for this layer).
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
        
        // Renderbuffer: 2D surface filled with data of a particular kind (in our case, color).
        //
        // Note that binding the renderbuffer to the pipeline allows subsequent OpenGL calls
        // to interact with that object.
        glGenRenderbuffers(1, &_renderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        
        // Framebuffer: A bundle of renderbuffers.
        glGenFramebuffers(1, &_framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        
        // Attach the framebuffer to the renderbuffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
        
        // Set the viewport size
        glViewport(0, 0, size.width, size.height);
        
        // Allocate storage for the renderbuffer in our graphics context.
        [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
        
        // Build the program
        self.simpleProgram = [self buildProgramWithVertexShaderName:@"SimpleVertex"
                                              andFragmentShaderName:@"SimpleFragment"];
        
        glUseProgram(self.simpleProgram);
        
        // Initialize our projection
        [self applyOrthoWithMaxX:2.0 andMaxY:3.0];
        
        // Initialize rotation
        [self handleRotationToOrientation:UIDeviceOrientationPortrait];
        self.currentRotationAngle = self.desiredRotationAngle;
    }
    
    return self;
}


#pragma mark - Program and Shaders

- (GLuint)buildProgramWithVertexShaderName:(NSString *)vertexShaderName andFragmentShaderName:(NSString *)fragmentShaderName
{
    GLuint vertexShaderHandle = [self compileShaderWithName:vertexShaderName andType:GL_VERTEX_SHADER];
    GLuint fragmentShaderHandle = [self compileShaderWithName:fragmentShaderName andType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShaderHandle);
    glAttachShader(programHandle, fragmentShaderHandle);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        
        NSLog(@"Program linking failed.");
        NSLog(@"Error message: %@", [NSString stringWithUTF8String:messages]);
        NSAssert(NO, @"Ending program due to program linking error.");
    }

    return programHandle;
}

- (GLuint)compileShaderWithName:(NSString *)shaderName andType:(GLenum)shaderType
{
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:SHADER_EXTENSION];
    
    NSError *fileReadError;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:&fileReadError];
    if (fileReadError) {
        NSLog(@"An error occurred while reading the shader file: %@", shaderName);
        NSLog(@"Error description: %@", fileReadError.localizedDescription);
        NSAssert(NO, @"Ending program due to file read error.");
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    const char  * shaderUTF8String = [shaderString UTF8String];
    glShaderSource(shaderHandle, 1, &shaderUTF8String, 0);
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        
        NSLog(@"Shader compilation failed.");
        NSLog(@"Error message: %@", [NSString stringWithUTF8String:messages]);
        NSAssert(NO, @"Ending program due to shader compilation error.");
    }
    
    return shaderHandle;
}



#pragma mark - Rendering & Animation

- (void)render
{
    glClearColor(0.5f, 0.5f, 0.5f, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self applyRotation:self.currentRotationAngle];
    
    GLuint positionSlot = glGetAttribLocation(self.simpleProgram, "Position");
    GLuint colorSlot = glGetAttribLocation(self.simpleProgram, "SourceColor");
    
    glEnableVertexAttribArray(positionSlot);
    glEnableVertexAttribArray(colorSlot);
    
    GLsizei stride = sizeof(Vertex);
    const GLvoid* pCoords = &Vertices[0].position[0];
    const GLvoid* pColors = &Vertices[0].color[0];
    
    glVertexAttribPointer(positionSlot, 2, GL_FLOAT, GL_FALSE, stride, pCoords);
    glVertexAttribPointer(colorSlot, 4, GL_FLOAT, GL_FALSE, stride, pColors);
    
    GLsizei vertexCount = sizeof(Vertices)/sizeof(Vertex);
    glDrawArrays(GL_TRIANGLES, 0, vertexCount);
    
    glDisableVertexAttribArray(positionSlot);
    glDisableVertexAttribArray(colorSlot);
}

- (void)updateAnimationWithTimestep:(float)timestep
{
    float directionToRotate = [self rotationDirection];
    if (directionToRotate == 0.0) {
        return;
    }
    
    float degrees = timestep * 360 * ROTATION_RPM;
    self.currentRotationAngle += degrees * directionToRotate;
    
    // Keep the rotation angle clamped within [0, 360)
    if (self.currentRotationAngle >= 360.0) {
        self.currentRotationAngle -= 360.0;
    }
    else if (self.currentRotationAngle < 0) {
        self.currentRotationAngle += 360.0;
    }
    
    // If the rotation direction has changed at this point, it
    // means we overshot our desired rotation angle. In this case,
    // we just snap the current rotation angle to the desired value.
    if ([self rotationDirection] != directionToRotate) {
        self.currentRotationAngle = self.desiredRotationAngle;
    }
}


#pragma mark - Matrices

- (void)applyOrthoWithMaxX:(float)maxX andMaxY:(float)maxY
{
    float a = 1.0/maxX;
    float b = 1.0/maxY;
    float ortho[16] = {
        a, 0, 0, 0,
        0, b, 0, 0,
        0, 0, -1, 0,
        0, 0, 0, 1
    };
    
    GLint projectionUniform = glGetUniformLocation(self.simpleProgram, "Projection");
    glUniformMatrix4fv(projectionUniform, 1, 0, &ortho[0]);
}

- (void)applyRotation:(float)degrees
{
    float radians = degrees * M_PI/180.0;
    float s = sinf(radians);
    float c = cosf(radians);
    float zRotation[16] = {
        c, s, 0, 0,
        -s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    };
    
    GLint modelviewUniform = glGetUniformLocation(self.simpleProgram, "Modelview");
    glUniformMatrix4fv(modelviewUniform, 1, 0, &zRotation[0]);
}


#pragma mark - Device Rotation

- (void)handleRotationToOrientation:(UIDeviceOrientation)orientation
{
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            self.desiredRotationAngle = 270;
            break;
        case UIDeviceOrientationPortrait:
            self.desiredRotationAngle = 180;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.desiredRotationAngle = 90;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            self.desiredRotationAngle = 0;
            break;
        default:
            self.desiredRotationAngle = 0;
            break;
    }
}

- (float)rotationDirection
{
    float delta = self.desiredRotationAngle - self.currentRotationAngle;
    if (delta == 0.0) {
        return 0;
    }
    
    BOOL counterclockwise = ((delta > 0.0) && (delta < 180.0)) || delta < -180.0;
    return counterclockwise ? 1.0 : -1.0;
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
