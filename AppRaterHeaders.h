//
//  AppRaterHeaders.h
//
//  Created by Oriol Blanc Gimeno on 26/07/12.
//  Copyright (c) 2012 Oriol Blanc Gimeno. All rights reserved.
//

@class AppRater;

@protocol AppRater <NSObject>
    @property (nonatomic, assign) BOOL debug;
    + (AppRater *)instance;

// setters
    + (void)setDebug:(BOOL)debug;
@end
