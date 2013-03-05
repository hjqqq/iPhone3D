//
//  AppDelegate.m
//  HelloArrow
//
//  Created by Derek Lyons on 3/4/13.
//  Copyright (c) 2013 Derek Lyons. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    self.window = [[UIWindow alloc] initWithFrame:screenBounds];
    self.glView = [[GLView alloc] initWithFrame:screenBounds];
    
    [self.window addSubview:self.glView];
    [self.window makeKeyAndVisible];
        
    return YES;
}

- (void)dealloc
{
    self.glView = nil;
    self.window = nil;
}

@end
