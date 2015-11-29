//
//  NSFont+SetupFont.m
//  MyMobileCleaner
//
//  Created by GoKu on 11/29/15.
//  Copyright © 2015 GoKuStudio. All rights reserved.
//

#import "NSFont+SetupFont.h"

const CGFloat kSetupFontWeightUltraLight = -0.8;
const CGFloat kSetupFontWeightThin = -0.6;
const CGFloat kSetupFontWeightLight = -0.4;
const CGFloat kSetupFontWeightRegular = 0.0;
const CGFloat kSetupFontWeightMedium = 0.23;
const CGFloat kSetupFontWeightSemibold = 0.3;
const CGFloat kSetupFontWeightBold = 0.4;
const CGFloat kSetupFontWeightHeavy = 0.56;
const CGFloat kSetupFontWeightBlack = 0.62;

@implementation NSFont (SetupFont)

+ (void)setupSystemFontForNSControl:(NSControl *)control withSize:(CGFloat)size weight:(CGFloat)weight
{
    if ([[NSFont class] respondsToSelector:@selector(systemFontOfSize:weight:)]) {
        // the argument type here should be exactly what it is in selector
        CGFloat theSize = size;
        CGFloat theWeight = weight;
        __unsafe_unretained NSFont *font; // must be __unsafe_unretained for return value of NSInvocation in ARC

        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[NSFont class] methodSignatureForSelector:@selector(systemFontOfSize:weight:)]];
        [inv setTarget:[NSFont class]];
        [inv setSelector:@selector(systemFontOfSize:weight:)];
        [inv setArgument:&theSize atIndex:2];
        [inv setArgument:&theWeight atIndex:3];
        [inv invoke];
        [inv getReturnValue:&font];

        if (font) {
            control.font = font;
        }
    }
}

@end
