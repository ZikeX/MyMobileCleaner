//
//  MCMainWindowController.m
//  MyMobileCleaner
//
//  Created by GoKu on 8/20/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "MCMainWindowController.h"
#import "MCConfig.h"
#import "NSFont+SetupFont.h"
#import "MCCustomWindowButtonBar.h"
#import "MCStageNoConnectionViewController.h"
#import "MCStageConnectedButUnPairedViewController.h"
#import "MCStageConnectedAndPairedViewController.h"
#import "MCStageScanningViewController.h"
#import "MCStageScanDoneViewController.h"
#import "MCStageCleaningViewController.h"
#import "MCStageCleanDoneViewController.h"

@interface MCMainWindowController ()

@property (weak) IBOutlet MCCustomWindowButtonBar *windowButtonBar;
@property (weak) IBOutlet NSView *cavas;
@property (weak) IBOutlet NSTextField *labelTitle;
@property (weak) IBOutlet NSTextField *labelInfo;
@property (weak) IBOutlet NSButton *btnSound;

@property (nonatomic, assign) MCStageViewControllerUIStage currentUIStage;
@property (nonatomic, strong) MCStageViewController *currentUIStageViewController;
@property (nonatomic, strong) MCStageNoConnectionViewController *stageNoConnectionViewController;
@property (nonatomic, strong) MCStageConnectedButUnPairedViewController *stageConnectedButUnPairedViewController;
@property (nonatomic, strong) MCStageConnectedAndPairedViewController *stageConnectedAndPairedViewController;
@property (nonatomic, strong) MCStageScanningViewController *stageScanningViewController;
@property (nonatomic, strong) MCStageScanDoneViewController *stageScanDoneViewController;
@property (nonatomic, strong) MCStageCleaningViewController *stageCleaningViewController;
@property (nonatomic, strong) MCStageCleanDoneViewController *stageCleanDoneViewController;

@end

@implementation MCMainWindowController

- (instancetype)init
{
    self = [super initWithWindowNibName:@"MCMainWindowController"];
    if (self) {
    }
    return self;
}

- (void)goToWork
{
    [[MCDeviceController sharedInstance] monitorWithListener:self];
}

- (void)takeAction
{
    [self.currentUIStageViewController respondToTakeActionCmd];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self setupFont];

    [self updateUIStatus];

    self.currentUIStage = -1;
    [self showDefaultDisConnectStatus];
}

- (void)setupFont
{
    [NSFont setupSystemFontForNSControl:self.labelInfo
                               withSize:16.0
                                 weight:kSetupFontWeightLight];
}

- (void)showDefaultDisConnectStatus
{
    self.labelTitle.stringValue = NSLocalizedStringFromTable(@"to.connect.title", @"MyMobileCleaner", @"to.connect");
    self.labelInfo.stringValue = NSLocalizedStringFromTable(@"to.connect.info", @"MyMobileCleaner", @"to.connect");

    [self updateStage:kMCStageViewControllerUIStageNoConnection animate:NO completion:nil];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[MCDeviceController sharedInstance] stopMonitor];

    // without delay, [windowWillClose:] will call 2 times. no idea.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSApplication sharedApplication] terminate:self];
    });
}

- (void)updateStage:(MCStageViewControllerUIStage)newStage
            animate:(BOOL)animate
         completion:(void(^)(MCStageViewController *))completion
{
    if (self.currentUIStage == newStage) {
        return;
    }

    DDLogDebug(@"UI stage change: %ld -> %ld", self.currentUIStage, newStage);

    if (self.currentUIStageViewController) {
        [self.currentUIStageViewController.view removeFromSuperview];
    }

    self.currentUIStage = newStage;
    switch (self.currentUIStage) {
        case kMCStageViewControllerUIStageNoConnection:
            if (!self.stageNoConnectionViewController) {
                self.stageNoConnectionViewController = [[MCStageNoConnectionViewController alloc] initWithManager:self];
            }
            self.currentUIStageViewController = self.stageNoConnectionViewController;
            self.infoForCurrentStage = NSLocalizedStringFromTable(@"info.stage.no.connection", @"MyMobileCleaner", @"stage");
            self.canTakeAction = NO;
            break;
            
        case kMCStageViewControllerUIStageConnectedButUnPaired:
            if (!self.stageConnectedButUnPairedViewController) {
                self.stageConnectedButUnPairedViewController = [[MCStageConnectedButUnPairedViewController alloc] initWithManager:self];
            }
            self.currentUIStageViewController = self.stageConnectedButUnPairedViewController;
            self.infoForCurrentStage = NSLocalizedStringFromTable(@"info.stage.device.unpaired", @"MyMobileCleaner", @"stage");
            self.canTakeAction = NO;
            break;
            
        case kMCStageViewControllerUIStageConnectedAndPaired:
            if (!self.stageConnectedAndPairedViewController) {
                self.stageConnectedAndPairedViewController = [[MCStageConnectedAndPairedViewController alloc] initWithManager:self];
            }
            self.currentUIStageViewController = self.stageConnectedAndPairedViewController;
            self.infoForCurrentStage = NSLocalizedStringFromTable(@"info.stage.scan", @"MyMobileCleaner", @"stage");
            self.canTakeAction = YES;
            break;
            
        case kMCStageViewControllerUIStageScanning:
            if (!self.stageScanningViewController) {
                self.stageScanningViewController = [[MCStageScanningViewController alloc] initWithManager:self];
            }
            self.currentUIStageViewController = self.stageScanningViewController;
            self.infoForCurrentStage = NSLocalizedStringFromTable(@"info.stage.scanning", @"MyMobileCleaner", @"stage");
            self.canTakeAction = NO;
            break;
            
        case kMCStageViewControllerUIStageScanDone:
            if (!self.stageScanDoneViewController) {
                self.stageScanDoneViewController = [[MCStageScanDoneViewController alloc] initWithManager:self];
            }
            self.currentUIStageViewController = self.stageScanDoneViewController;
            self.infoForCurrentStage = NSLocalizedStringFromTable(@"info.stage.clean", @"MyMobileCleaner", @"stage");
            self.canTakeAction = YES;
            break;
            
        case kMCStageViewControllerUIStageCleaning:
            if (!self.stageCleaningViewController) {
                self.stageCleaningViewController = [[MCStageCleaningViewController alloc] initWithManager:self];
            }
            self.currentUIStageViewController = self.stageCleaningViewController;
            self.infoForCurrentStage = NSLocalizedStringFromTable(@"info.stage.cleaning", @"MyMobileCleaner", @"stage");
            self.canTakeAction = NO;
            break;
            
        case kMCStageViewControllerUIStageCleanDone:
            if (!self.stageCleanDoneViewController) {
                self.stageCleanDoneViewController = [[MCStageCleanDoneViewController alloc] initWithManager:self];
            }
            self.currentUIStageViewController = self.stageCleanDoneViewController;
            self.infoForCurrentStage = NSLocalizedStringFromTable(@"info.stage.done", @"MyMobileCleaner", @"stage");
            self.canTakeAction = YES;
            break;
            
        default:
            break;
    }

    [self.cavas addSubview:self.currentUIStageViewController.view];
    [self.cavas addConstraints:@[[NSLayoutConstraint constraintWithItem:self.currentUIStageViewController.view
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cavas
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:self.currentUIStageViewController.view
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cavas
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:self.currentUIStageViewController.view
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cavas
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:self.currentUIStageViewController.view
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cavas
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1
                                                               constant:0]]];

    [self.currentUIStageViewController stageViewDidAppear];

    [self refreshWindowButtonBar];
}

- (void)refreshWindowButtonBar
{
    [self.windowButtonBar removeFromSuperviewWithoutNeedingDisplay];
    [self.window.contentView addSubview:self.windowButtonBar];
    [self.window.contentView addConstraints:@[[NSLayoutConstraint constraintWithItem:self.windowButtonBar
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.window.contentView
                                                                           attribute:NSLayoutAttributeTop
                                                                          multiplier:1
                                                                            constant:16],
                                              [NSLayoutConstraint constraintWithItem:self.windowButtonBar
                                                                           attribute:NSLayoutAttributeLeading
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.window.contentView
                                                                           attribute:NSLayoutAttributeLeading
                                                                          multiplier:1
                                                                            constant:16]]];
    [self.windowButtonBar layoutButtonsVertical:YES];
}

- (void)updateUIStatus
{
    self.btnSound.toolTip = [MCConfig isSoundEffectDisabled] ? NSLocalizedStringFromTable(@"main.tip.soundeffect.switchon", @"MyMobileCleaner", @"tip") : NSLocalizedStringFromTable(@"main.tip.soundeffect.switchoff", @"MyMobileCleaner", @"tip");

    self.btnSound.image = [MCConfig isSoundEffectDisabled] ? [NSImage imageNamed:@"soundoff"] : [NSImage imageNamed:@"soundon"];
    self.btnSound.alternateImage = self.btnSound.image;
}

- (IBAction)clickBtnSound:(id)sender
{
    [MCConfig setSoundEffectDisabled:![MCConfig isSoundEffectDisabled]];

    [self updateUIStatus];
}

#pragma mark - MCStageViewControllerManager

- (void)gotoNextStage
{
    if (self.currentUIStage == kMCStageViewControllerUIStageConnectedAndPaired) {
        [self updateStage:kMCStageViewControllerUIStageScanning animate:NO completion:nil];

    } else if (self.currentUIStage == kMCStageViewControllerUIStageScanning) {
        [self updateStage:kMCStageViewControllerUIStageScanDone animate:NO completion:nil];

    } else if (self.currentUIStage == kMCStageViewControllerUIStageScanDone) {
        [self updateStage:kMCStageViewControllerUIStageCleaning animate:NO completion:nil];

    } else if (self.currentUIStage == kMCStageViewControllerUIStageCleaning) {
        [self updateStage:kMCStageViewControllerUIStageCleanDone animate:NO completion:nil];

    } else if (self.currentUIStage == kMCStageViewControllerUIStageCleanDone) {
        [self updateStage:kMCStageViewControllerUIStageConnectedAndPaired animate:NO completion:nil];

    } else {

    }
}

- (void)gotoPreviousStage
{
    if (self.currentUIStage == kMCStageViewControllerUIStageScanning) {
        [self updateStage:kMCStageViewControllerUIStageConnectedAndPaired animate:NO completion:nil];

    } else if (self.currentUIStage == kMCStageViewControllerUIStageScanDone) {
        [self updateStage:kMCStageViewControllerUIStageConnectedAndPaired animate:NO completion:nil];

    } else if (self.currentUIStage == kMCStageViewControllerUIStageCleaning) {
        [self updateStage:kMCStageViewControllerUIStageConnectedAndPaired animate:NO completion:nil];

    } else {

    }
}

#pragma mark - MCDeviceControllerDelegate

- (void)deviceDidConnectButUnPaired
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.labelTitle.stringValue = [MCDeviceController sharedInstance].selectedConnectedDevice.deviceName;
        self.labelInfo.stringValue = NSLocalizedStringFromTable(@"to.pair.info", @"MyMobileCleaner", @"to.pair");

        [self updateStage:kMCStageViewControllerUIStageConnectedButUnPaired animate:NO completion:nil];
    });

    [[MCDeviceController sharedInstance].selectedConnectedDevice waitingForPairWithCompleteBlock:^{
        [self deviceDidConnectAndPaired];
    }];
}

- (void)deviceDidConnectAndPaired
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.labelTitle.stringValue = [MCDeviceController sharedInstance].selectedConnectedDevice.deviceName;
        self.labelInfo.stringValue = [MCDeviceController sharedInstance].selectedConnectedDevice.deviceType;

        [self updateStage:kMCStageViewControllerUIStageConnectedAndPaired animate:NO completion:nil];
    });
}

- (void)deviceDidDisconnect
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showDefaultDisConnectStatus];
    });
}

@end
