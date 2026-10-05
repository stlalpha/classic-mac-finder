//
//  CCIApplicationStyles.m
//  Classic Finder
//
//  Created by Ben Szymanski on 12/2/17.
//  Copyright © 2017 Protype Software Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "CCIApplicationStyles.h"

@interface CCIApplicationStyles()
{
    NSColor *whiteColor;
    NSColor *blackColor;
    NSColor *darkPurpleColor;
    NSColor *midPurpleColor;
    NSColor *lightPurpleColor;
    NSColor *darkGrayColor;
    NSColor *midGrayColor;
    NSColor *lightGrayColor;
    NSColor *clickedMidGrayColor;
    NSColor *clickedDarkPurpleColor;
    NSColor *clickedLightPurpleColor;
    NSColor *folderShadowColor;
    NSColor *folderSelectedHighlightColor;
    NSColor *folderSelectedShadowColor;
    NSColor *folderOpenedBackgroundColor;
    NSColor *folderOpenedAndSelectedBackgroundColor;
}

@end

@implementation CCIApplicationStyles

- (CCIClassicAppearanceVersion)appearanceVersion
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSNumber *storedVersion = [defaults objectForKey:@"ClassicFinderAppearanceVersion"];
    return storedVersion ? (CCIClassicAppearanceVersion)storedVersion.integerValue : CCIClassicAppearanceMacOS9;
}

- (void)setAppearanceVersion:(CCIClassicAppearanceVersion)appearanceVersion
{
    [[NSUserDefaults standardUserDefaults] setInteger:appearanceVersion forKey:@"ClassicFinderAppearanceVersion"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CCIClassicAppearanceDidChange" object:nil];
}

- (NSFont *)classicBodyFontOfSize:(CGFloat)size
{
    return [NSFont fontWithName:@"Geneva" size:size] ?: [NSFont systemFontOfSize:size];
}

- (NSFont *)classicTitleFontOfSize:(CGFloat)size
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) {
        return [NSFont fontWithName:@"Charcoal" size:size]
            ?: [NSFont fontWithName:@"ChicagoBold" size:size]
            ?: [NSFont boldSystemFontOfSize:size];
    }
    return [NSFont fontWithName:@"Chicago" size:size]
        ?: [NSFont fontWithName:@"ChicagoBold" size:size]
        ?: [NSFont boldSystemFontOfSize:size];
}

#pragma mark - INITIALIZATION

+ (instancetype)instance
{
    static CCIApplicationStyles *styleStore = nil;
    static dispatch_once_t initOneTimeToken;
    
    dispatch_once(&initOneTimeToken, ^{
        styleStore = [[self alloc] initHidden];
    });
    
    return styleStore;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton Init Warning"
                                   reason:@"Use +[instance]"
                                 userInfo:nil];
    
    return nil;
}

- (instancetype)initHidden
{
    self = [super init];
    
    if (self) { }
    
    return self;
}

#pragma mark - GENERAL COLORS

- (NSColor *)whiteColor
{
    if (whiteColor == nil) {
        whiteColor = [NSColor colorWithWhite:1.0 alpha:1.0];
    }
    
    return whiteColor;
}

- (NSColor *)blackColor
{
    if (blackColor == nil) {
        blackColor = [NSColor colorWithWhite:0.0 alpha:1.0];
    }
    
    return blackColor;
}

- (NSColor *)darkPurpleColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedRed:0.18 green:0.24 blue:0.42 alpha:1.0];
    if (darkPurpleColor == nil) {
        darkPurpleColor = [NSColor colorWithCalibratedRed:0.15
                                                    green:0.14
                                                     blue:0.31
                                                    alpha:1.0];
    }
    
    return darkPurpleColor;
}

- (NSColor *)midPurpleColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedWhite:0.62 alpha:1.0];
    if (midPurpleColor == nil) {
        midPurpleColor = [NSColor colorWithCalibratedRed:0.58
                                                   green:0.57
                                                    blue:0.80
                                                   alpha:1.0];
    }
    
    return midPurpleColor;
}

- (NSColor *)lightPurpleColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedRed:0.76 green:0.83 blue:0.97 alpha:1.0];
    if (lightPurpleColor == nil) {
        lightPurpleColor = [NSColor colorWithCalibratedRed:0.76
                                                     green:0.76
                                                      blue:1.0
                                                     alpha:1.0];
    }
    
    return lightPurpleColor;
}

- (NSColor *)darkGrayColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedWhite:0.48 alpha:1.0];
    if (darkGrayColor == nil) {
        darkGrayColor = [NSColor colorWithCalibratedWhite:0.38
                                                   alpha:1.0];
    }
    
    return darkGrayColor;
}

- (NSColor *)midGrayColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedWhite:0.70 alpha:1.0];
    if (midGrayColor == nil) {
        midGrayColor = [NSColor colorWithCalibratedWhite:0.58
                                                     alpha:1.0];
    }
    
    return midGrayColor;
}

- (NSColor *)lightGrayColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedWhite:0.84 alpha:1.0];
    if (lightGrayColor == nil) {
        lightGrayColor = [NSColor colorWithCalibratedWhite:0.92
                                                     alpha:1.0];
    }
    
    return lightGrayColor;
}

#pragma mark - GENERAL CLICKED COLORS

- (NSColor *)clickedMidGrayColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedWhite:0.58 alpha:1.0];
    if (clickedMidGrayColor == nil) {
        clickedMidGrayColor = [NSColor colorWithCalibratedWhite:0.45
                                                          alpha:1.0];
    }
    
    return clickedMidGrayColor;
}

- (NSColor *)clickedDarkPurpleColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedRed:0.12 green:0.18 blue:0.34 alpha:1.0];
    if (clickedDarkPurpleColor == nil) {
        clickedDarkPurpleColor = [NSColor colorWithCalibratedRed:0.14
                                                           green:0.13
                                                            blue:0.30
                                                           alpha:1.0];
    }
    
    return clickedDarkPurpleColor;
}

- (NSColor *)clickedLightPurpleColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedRed:0.61 green:0.71 blue:0.89 alpha:1.0];
    if (clickedLightPurpleColor == nil) {
        clickedLightPurpleColor = [NSColor colorWithCalibratedRed:0.70
                                                            green:0.70
                                                             blue:0.96
                                                            alpha:1.0];
    }
    
    return clickedLightPurpleColor;
}

#pragma mark - FOLDER ICON COLORS

- (NSColor *)folderShadowColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) {
        return [NSColor colorWithCalibratedWhite:0.42 alpha:1.0];
    }
    if (folderShadowColor == nil) folderShadowColor = [NSColor colorWithCalibratedRed:0.70 green:0.70 blue:0.96 alpha:1.0];
    return folderShadowColor;
}

- (NSColor *)folderSelectedHighlightColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedRed:0.48 green:0.58 blue:0.78 alpha:1.0];
    if (folderSelectedHighlightColor == nil) {
        folderSelectedHighlightColor = [NSColor colorWithCalibratedRed:0.41
                                                                 green:0.41
                                                                  blue:0.41
                                                                 alpha:1.0];
    }
    
    return folderSelectedHighlightColor;
}

- (NSColor *)folderSelectedShadowColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedRed:0.18 green:0.24 blue:0.42 alpha:1.0];
    if (folderSelectedShadowColor == nil) {
        folderSelectedShadowColor = [NSColor colorWithCalibratedRed:0.10
                                                              green:0.07
                                                               blue:0.41
                                                              alpha:1.0];
    }
    
    return folderSelectedShadowColor;
}

- (NSColor *)folderOpenedBackgroundColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedRed:0.82 green:0.85 blue:0.92 alpha:1.0];
    if (folderOpenedBackgroundColor == nil) {
        folderOpenedBackgroundColor = [NSColor colorWithCalibratedRed:0.77
                                                                green:0.77
                                                                 blue:0.95
                                                                alpha:1.0];
    }
    
    return folderOpenedBackgroundColor;
}

- (NSColor *)folderOpenedAndSelectedBackgroundColor
{
    if (self.appearanceVersion == CCIClassicAppearanceMacOS9) return [NSColor colorWithCalibratedRed:0.48 green:0.58 blue:0.78 alpha:1.0];
    if (folderOpenedAndSelectedBackgroundColor == nil) {
        folderOpenedAndSelectedBackgroundColor = [NSColor colorWithCalibratedRed:0.19
                                                                           green:0.19
                                                                            blue:0.48
                                                                           alpha:1.00];
    }
    
    return folderOpenedAndSelectedBackgroundColor;
}

- (NSColor *)labelColorForIndex:(NSInteger)labelIndex
{
    NSArray<NSColor *> *colors = @[
        NSColor.clearColor,
        [NSColor colorWithCalibratedRed:1.0 green:0.72 blue:0.72 alpha:1.0],
        [NSColor colorWithCalibratedRed:1.0 green:0.82 blue:0.64 alpha:1.0],
        [NSColor colorWithCalibratedRed:1.0 green:0.94 blue:0.62 alpha:1.0],
        [NSColor colorWithCalibratedRed:0.73 green:0.92 blue:0.70 alpha:1.0],
        [NSColor colorWithCalibratedRed:0.67 green:0.86 blue:1.0 alpha:1.0],
        [NSColor colorWithCalibratedRed:0.82 green:0.74 blue:1.0 alpha:1.0],
        [NSColor colorWithCalibratedWhite:0.82 alpha:1.0]
    ];
    if (labelIndex < 0 || labelIndex >= (NSInteger)colors.count) return NSColor.clearColor;
    return colors[(NSUInteger)labelIndex];
}


@end
