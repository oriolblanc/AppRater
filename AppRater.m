//
//  AppRater.m
//
//  Created by Oriol Blanc Gimeno on 25/07/12.
//  Copyright (c) 2012 Oriol Blanc Gimeno. All rights reserved.
//

#import "AppRater.h"

NSString *const kRateriTuneesAppId			= @"kRateriTuneesAppId";
NSString *const kRaterFirstUseDate			= @"kRaterFirstUseDate";
NSString *const kRaterUseCount				= @"RaterUseCount";
NSString *const kRaterSignificantEventCount	= @"RaterSignificantEventCount";
NSString *const kRaterCurrentVersion		= @"kRaterCurrentVersion";
NSString *const kRaterRatedCurrentVersion	= @"kRaterRatedCurrentVersion";
NSString *const kRaterDeclinedToRate		= @"kRaterDeclinedToRate";
NSString *const kRaterReminderRequestDate	= @"kRaterReminderRequestDate";

NSString *templateReviewURL = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=APP_ID";

#define kDefaultUsesToPrompt 10
#define kDefaultDaysToPrompt 10.0f
#define kDefaultDaysToRemind 1.0f


@interface AppRater()
- (void)setUpAppRater;
- (void)increaseUsageCount;
- (BOOL)shouldPromptForRating;
@end

@implementation AppRater
@synthesize debug = _debug;
@synthesize daysToPrompt = _daysToPrompt;
@synthesize usesToPrompt = _usesToPrompt;
@synthesize daysToRemind = _daysToRemind;

@synthesize alertTitle = _alertTitle;
@synthesize alertMessage = _alertMessage;
@synthesize alertCancelButton = _alertCancelButton;
@synthesize alertRemindButton = _alertRemindButton;
@synthesize alertRateButton = _alertRateButton;

+ (void)takeOff:(NSString *)appId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:appId forKey:kRateriTuneesAppId];
	[userDefaults synchronize];
    
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
        
        self.usesToPrompt = kDefaultUsesToPrompt;
        self.daysToPrompt = kDefaultDaysToPrompt;
        self.daysToRemind = kDefaultDaysToRemind;
        
        self.alertTitle = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Rate", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
        
        self.alertMessage = [NSString stringWithFormat:NSLocalizedString(@"If you enjoy using %@, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
        self.alertCancelButton = NSLocalizedString(@"No, Thanks", nil);
        self.alertRemindButton = NSLocalizedString(@"Remind Me Later", nil);
        self.alertRateButton = NSLocalizedString(@"Rate It Now", nil);
        
        // On iOS 4.0+ only, listen for foreground notification
        if(&UIApplicationWillEnterForegroundNotification != nil)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpAppRater) name:UIApplicationWillEnterForegroundNotification object:nil];
        }
    }
    return self;
}

- (void)setUpAppRater
{
    [self increaseUsageCount];
    
	if ([self shouldPromptForRating])
	{
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self showRatingAlert];
        });
	}
}

- (BOOL)shouldPromptForRating 
{
    if (self.debug == YES)
        return YES;
    
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
	NSDate *dateOfFirstLaunch = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kRaterFirstUseDate]];
	NSTimeInterval timeSinceFirstLaunch = [[NSDate date] timeIntervalSinceDate:dateOfFirstLaunch];
	NSTimeInterval timeUntilRate = 60 * 60 * 24 * self.daysToPrompt;
	if (timeSinceFirstLaunch < timeUntilRate)
		return NO;
    
	// check if the app has been used enough
	int useCount = [userDefaults integerForKey:kRaterUseCount];
	if (useCount <= self.usesToPrompt)
		return NO;
        
	// has the user previously declined to rate this version of the app?
	if ([userDefaults boolForKey:kRaterDeclinedToRate])
		return NO;
    
	// has the user already rated the app?
	if ([userDefaults boolForKey:kRaterRatedCurrentVersion])
		return NO;
    
	// if the user wanted to be reminded later, has enough time passed?
	NSDate *reminderRequestDate = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kRaterReminderRequestDate]];
	NSTimeInterval timeSinceReminderRequest = [[NSDate date] timeIntervalSinceDate:reminderRequestDate];
	NSTimeInterval timeUntilReminder = 60 * 60 * 24 * self.daysToRemind;
	if (timeSinceReminderRequest < timeUntilReminder)
		return NO;
    
	return YES;
}

- (void)showRatingAlert 
{
	UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:self.alertTitle
														 message:self.alertMessage
														delegate:self
											   cancelButtonTitle:self.alertCancelButton
											   otherButtonTitles:self.alertRateButton, self.alertRemindButton, nil] autorelease];
//	self.ratingAlert = alertView;
	[alertView show];
}

- (void)increaseUsageCount 
{
	// get the app's version
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
    
	// get the version number that we've been tracking
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *trackingVersion = [userDefaults stringForKey:kRaterCurrentVersion];
	if (trackingVersion == nil)
	{
		trackingVersion = version;
		[userDefaults setObject:version forKey:kRaterCurrentVersion];
	}
    
	if ([trackingVersion isEqualToString:version])
	{
		// check if the first use date has been set. if not, set it.
		NSTimeInterval timeInterval = [userDefaults doubleForKey:kRaterFirstUseDate];
		if (timeInterval == 0)
		{
			timeInterval = [[NSDate date] timeIntervalSince1970];
			[userDefaults setDouble:timeInterval forKey:kRaterFirstUseDate];
		}
        
		// increment the use count
		int useCount = [userDefaults integerForKey:kRaterUseCount];
		useCount++;
		[userDefaults setInteger:useCount forKey:kRaterUseCount];
	}
	else
	{
		// it's a new version of the app, so restart tracking
		[userDefaults setObject:version forKey:kRaterCurrentVersion];
		[userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kRaterFirstUseDate];
		[userDefaults setInteger:1 forKey:kRaterUseCount];
		[userDefaults setInteger:0 forKey:kRaterSignificantEventCount];
		[userDefaults setBool:NO forKey:kRaterRatedCurrentVersion];
		[userDefaults setBool:NO forKey:kRaterDeclinedToRate];
		[userDefaults setDouble:0 forKey:kRaterReminderRequestDate];
	}
    
	[userDefaults synchronize];
}

+ (void)rate
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:YES forKey:kRaterRatedCurrentVersion];
	[userDefaults synchronize];
    
    
	NSString *reviewURL = [templateReviewURL stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", [userDefaults stringForKey:kRateriTuneesAppId]]];
    
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
	switch (buttonIndex) 
    {
		case 0:
		{
			[userDefaults setBool:YES forKey:kRaterDeclinedToRate];
			break;
		}
		case 1:
		{
			[[self class] rate];
			break;
		}
		case 2:
        {
			[userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kRaterReminderRequestDate];
			break;
        }
		default:
			break;
	}
    
    [userDefaults synchronize];
}

#pragma mark - Setting configuration

+ (void)setDebug:(BOOL)debug
{
    [[self instance] setDebug:debug];
}

#pragma mark - Memory Management

- (void)dealloc
{
    [_alertTitle release];
    [_alertMessage release];
    [_alertCancelButton release];
    [_alertRemindButton release];
    [_alertRateButton release];
    
    [super dealloc];
}

@end
