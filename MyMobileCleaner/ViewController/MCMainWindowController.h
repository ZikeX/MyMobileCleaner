//
//  MCMainWindowController.h
//  MyMobileCleaner
//
//  Created by GoKu on 8/20/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCDeviceController.h"
#import "MCStageViewController.h"

@interface MCMainWindowController : NSWindowController <NSWindowDelegate, MCStageViewControllerManager, MCDeviceControllerDelegate>

@property (nonatomic, strong) NSArray *myCrashLogs;

@property (nonatomic, strong) NSString *infoForCurrentStage;
@property (nonatomic, assign) BOOL canTakeAction;
- (void)takeAction;

- (void)goToWork;

@end
