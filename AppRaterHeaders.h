//
//  AppRaterHeaders.h
//
//  Created by Oriol Blanc Gimeno on 26/07/12.
//  Copyright (c) 2012 Oriol Blanc Gimeno. All rights reserved.
//

@class AppRater;

@protocol AppRater <NSObject>
    @property (nonatomic, assign) BOOL debug;
    @property (nonatomic, assign) int usesToPrompt;
    @property (nonatomic, assign) float daysToPrompt;
    @property (nonatomic, assign) float daysToRemind;

    @property (nonatomic, copy) NSString *alertTitle;
    @property (nonatomic, copy) NSString *alertMessage;
    @property (nonatomic, copy) NSString *alertCancelButton;
    @property (nonatomic, copy) NSString *alertRemindButton;
    @property (nonatomic, copy) NSString *alertRateButton;
    + (AppRater *)instance;
    + (void)rate;

// setters
    + (void)setDebug:(BOOL)debug;
@end

