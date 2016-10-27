//
//  MCStageScanDoneViewController.m
//  MyMobileCleaner
//
//  Created by GoKu on 8/21/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "MCStageScanDoneViewController.h"
#import "MCMainWindowController.h"
#import "MCFlashRingView.h"
#import "MCStageScanDonePopoverCellView.h"

static NSUInteger const kMaxNumberOfRowsInPopoverTableView = 7;

@interface MCStageScanDoneViewController ()

@property (weak) IBOutlet MCColorBackgroundView *colorBackground;
@property (weak) IBOutlet NSButton *btnClean;
@property (weak) IBOutlet NSTextField *labelSize;
@property (weak) IBOutlet MCFlashRingView *flashRing;

@property (weak) IBOutlet NSButton *btnInfo;
@property (strong) IBOutlet NSPopover *infoPopover;
@property (weak) IBOutlet NSTableView *infoTableView;
@property (weak) IBOutlet NSLayoutConstraint *constraintTableViewHeight;

@property (nonatomic, strong) NSMutableArray *allFilesName;
@property (nonatomic, strong) NSMutableArray *allFilesNameForShow;

@end

@implementation MCStageScanDoneViewController

- (instancetype)initWithManager:(id<MCStageViewControllerManager>)manager
{
    self = [super initWithNibName:@"MCStageScanDoneViewController" bundle:nil];
    if (self) {
        self.manager = manager;
    }
    return self;
}

- (void)setupFont
{
    [NSFont setupSystemFontForNSControl:self.btnClean
                               withSize:40.0
                                 weight:kSetupFontWeightUltraLight];
}

- (void)loadView
{
    [super loadView];
    
    [self setupFont];
}

- (void)stageViewDidAppear
{
    [self.flashRing startFlashRingWithColor:[NSColor greenColor]];

    NSUInteger totalSize = 0;
    NSMutableArray *allFiles = [NSMutableArray array];
    for (MCDeviceCrashLogItem *item in ((MCMainWindowController *)(self.manager)).myCrashLogs) {
        totalSize += [item.totalSize unsignedIntegerValue];
        [allFiles addObjectsFromArray:item.allFiles];
    }

    self.allFilesName = [NSMutableArray array];
    self.allFilesNameForShow = [NSMutableArray array];
    NSUInteger totalSizeForShow = 0;
    for (MCDeviceCrashLogFileInfo *fileInfo in allFiles) {
        [self.allFilesName addObject:fileInfo.filePath];

        if (![self shouldFilterLogPath:fileInfo.filePath]) {
            totalSizeForShow += fileInfo.fileSize;
            [self.allFilesNameForShow addObject:fileInfo.filePath.lastPathComponent];
        }
    }

    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    formatter.countStyle = NSByteCountFormatterCountStyleBinary;
    formatter.adaptive = NO;
    formatter.zeroPadsFractionDigits = YES;

    DDLogDebug(@"100%% => all scanned crash log: %@", [formatter stringFromByteCount:totalSize]);
    DDLogDebug(@"100%% => all scanned crash log: %@", self.allFilesName);

    self.labelSize.stringValue = [NSString stringWithFormat:((self.allFilesNameForShow.count > 1) ? NSLocalizedStringFromTable(@"scan.done.crash.log.info.many", @"MyMobileCleaner", @"scan.done") : NSLocalizedStringFromTable(@"scan.done.crash.log.info.single", @"MyMobileCleaner", @"scan.done")),
                                  @(self.allFilesNameForShow.count),
                                  [formatter stringFromByteCount:totalSizeForShow]];

    self.btnInfo.hidden = !(self.allFilesNameForShow.count > 0);
    
    [self.infoTableView reloadData];
}

- (void)respondToTakeActionCmd
{
    [self clickBtnClean:self.btnClean];
}

- (BOOL)shouldFilterLogPath:(NSString *)path
{
    BOOL should = NO;

    if ([path hasPrefix:@"WiFi/WiFiManager/"]) {
        should = YES;
    }

    return should;
}

- (void)resetHeightForTableView
{
    if (self.infoTableView.numberOfRows == 0) {
        self.constraintTableViewHeight.constant = 0;

    } else {
        NSUInteger rows = MIN(self.infoTableView.numberOfRows, kMaxNumberOfRowsInPopoverTableView);
        self.constraintTableViewHeight.constant = rows * ((NSView *)[self.infoTableView rowViewAtRow:0 makeIfNecessary:YES]).frame.size.height;
    }
}

- (IBAction)clickInfo:(id)sender {
    NSButton *infoButton = sender;

    [self resetHeightForTableView];
    [self.infoPopover showRelativeToRect:infoButton.bounds
                                  ofView:infoButton
                           preferredEdge:NSMinYEdge];
}


- (IBAction)clickBtnClean:(id)sender {
    [self.flashRing stopFlashRing];
    [self.manager gotoNextStage];
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return self.allFilesNameForShow.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    MCStageScanDonePopoverCellView *cellView = [tableView makeViewWithIdentifier:@"MCStageScanDonePopoverCellView" owner:self];
    [NSFont setupSystemFontForNSControl:cellView.name
                               withSize:14.0
                                 weight:kSetupFontWeightLight];
    cellView.name.stringValue = self.allFilesNameForShow[row];

    return cellView;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    if (aTableView == self.infoTableView) {
        return NO;
    }
    
    return YES;
}

@end
