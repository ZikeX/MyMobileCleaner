//
//  MCStageConnectedAndPairedViewController.m
//  MyMobileCleaner
//
//  Created by GoKu on 8/21/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "MCStageConnectedAndPairedViewController.h"
#import "MCMainWindowController.h"
#import "MCDiskUsageCircleView.h"
#import "SoundManager.h"
#import "MCConfig.h"

@interface MCStageConnectedAndPairedViewController ()

@property (weak) IBOutlet MCColorBackgroundView *colorBackground;
@property (weak) IBOutlet NSButton *btnScan;
@property (weak) IBOutlet MCDiskUsageCircleView *chartDiskUsage;
@property (weak) IBOutlet NSView *boxUsed;
@property (weak) IBOutlet NSView *boxReserved;
@property (weak) IBOutlet NSView *boxFree;
@property (weak) IBOutlet NSTextField *labelSizeUsed;
@property (weak) IBOutlet NSTextField *labelSizeReserved;
@property (weak) IBOutlet NSTextField *labelSizeFree;
@property (weak) IBOutlet NSTextField *labelCatUsed;
@property (weak) IBOutlet NSTextField *labelCatReserved;
@property (weak) IBOutlet NSTextField *labelCatFree;

@end

@implementation MCStageConnectedAndPairedViewController

- (instancetype)initWithManager:(id<MCStageViewControllerManager>)manager
{
    self = [super initWithNibName:@"MCStageConnectedAndPairedViewController" bundle:nil];
    if (self) {
        self.manager = manager;
    }
    return self;
}

- (void)setupFont
{
    [NSFont setupSystemFontForNSControl:self.btnScan
                               withSize:40.0
                                 weight:kSetupFontWeightUltraLight];

    [NSFont setupSystemFontForNSControl:self.labelSizeUsed
                               withSize:13.0
                                 weight:kSetupFontWeightLight];
    [NSFont setupSystemFontForNSControl:self.labelSizeReserved
                               withSize:13.0
                                 weight:kSetupFontWeightLight];
    [NSFont setupSystemFontForNSControl:self.labelSizeFree
                               withSize:13.0
                                 weight:kSetupFontWeightLight];
    [NSFont setupSystemFontForNSControl:self.labelCatUsed
                               withSize:13.0
                                 weight:kSetupFontWeightLight];
    [NSFont setupSystemFontForNSControl:self.labelCatReserved
                               withSize:13.0
                                 weight:kSetupFontWeightLight];
    [NSFont setupSystemFontForNSControl:self.labelCatFree
                               withSize:13.0
                                 weight:kSetupFontWeightLight];
}

- (void)loadView
{
    [super loadView];

    [self setupFont];
}

- (void)stageViewDidAppear
{
    ((MCMainWindowController *)(self.manager)).myCrashLogs = nil;
    
    // disk usage
    MCDeviceDiskUsage *diskUsage = [[MCDeviceController sharedInstance].selectedConnectedDevice diskUsage];
    if (!diskUsage) {
        DDLogError(@"failed to access disk usage");
        return;
    }

    DDLogDebug(@"%@", diskUsage);

    self.boxUsed.hidden = YES;
    self.boxReserved.hidden = YES;
    self.boxFree.hidden = YES;

    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    formatter.countStyle = NSByteCountFormatterCountStyleBinary;
    formatter.adaptive = NO;
    formatter.zeroPadsFractionDigits = YES;
    self.labelSizeUsed.stringValue = [formatter stringFromByteCount:[diskUsage.totalDiskUsed unsignedIntegerValue]];
    self.labelSizeReserved.stringValue = [formatter stringFromByteCount:[diskUsage.totalDiskReserved unsignedIntegerValue]];
    self.labelSizeFree.stringValue = [formatter stringFromByteCount:[diskUsage.totalDiskFree unsignedIntegerValue]];

    [self.chartDiskUsage updateWithData:@[diskUsage.totalDiskUsed,
                                          diskUsage.totalDiskReserved,
                                          diskUsage.totalDiskFree]
                                  color:@[[NSColor redColor],
                                          [NSColor yellowColor],
                                          [NSColor greenColor]]
                               animation:^(NSUInteger dataIndex) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       if (![MCConfig isSoundEffectDisabled]) {
                                           [[Sound soundNamed:@"bubbles.mp3"] play];
                                       }

                                       if (dataIndex == 0) {
                                           self.boxUsed.hidden = NO;
                                       } else if (dataIndex == 1) {
                                           self.boxReserved.hidden = NO;
                                       } else if (dataIndex == 2) {
                                           self.boxFree.hidden = NO;
                                       }
                                   });
                               }
                             completion:nil];
}

- (void)respondToTakeActionCmd
{
    [self clickBtnScan:self.btnScan];
}

- (IBAction)clickBtnScan:(id)sender {
    [self.manager gotoNextStage];
}

@end
