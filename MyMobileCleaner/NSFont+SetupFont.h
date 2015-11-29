//
//  NSFont+SetupFont.h
//  MyMobileCleaner
//
//  Created by GoKu on 11/29/15.
//  Copyright © 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>

APPKIT_EXTERN const CGFloat kSetupFontWeightUltraLight;
APPKIT_EXTERN const CGFloat kSetupFontWeightThin;
APPKIT_EXTERN const CGFloat kSetupFontWeightLight;
APPKIT_EXTERN const CGFloat kSetupFontWeightRegular;
APPKIT_EXTERN const CGFloat kSetupFontWeightMedium;
APPKIT_EXTERN const CGFloat kSetupFontWeightSemibold;
APPKIT_EXTERN const CGFloat kSetupFontWeightBold;
APPKIT_EXTERN const CGFloat kSetupFontWeightHeavy;
APPKIT_EXTERN const CGFloat kSetupFontWeightBlack;

@interface NSFont (SetupFont)

+ (void)setupSystemFontForNSControl:(NSControl *)control withSize:(CGFloat)size weight:(CGFloat)weight;

@end
