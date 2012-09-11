//
//  AppRater.m
//
//  Created by Oriol Blanc Gimeno on 25/07/12.
//  Copyright (c) 2012 Oriol Blanc Gimeno. All rights reserved.
//

#import "AppRater.h"

@implementation AppRater
@synthesize debug = _debug;

+ (void)takeOff:(NSString *)appId
{
    [[self instance] setUpAppRater];
}

+ (AppRater *)instance 
{
	static AppRater *appRater = nil;
	if (appRater == nil)
	{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            appRater = [[AppRater alloc] init];
        });
	}
    
	return appRater;
}

- (id)init
{
    if ((self = [super init]))
    {        
        self.debug = NO;
        
        // On iOS 4.0+ only, listen for foreground notification
        if(&UIApplicationWillEnterForegroundNotification != nil)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpAppRater) name:UIApplicationWillEnterForegroundNotification object:nil];
        }
    }
    return self;
}


@end
