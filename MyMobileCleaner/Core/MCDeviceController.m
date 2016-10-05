//
//  MCDeviceController.m
//  MyMobileCleaner
//
//  Created by GoKu on 8/18/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "MCDeviceController.h"
#import "LogFormatter.h"

@interface MCDeviceController () <MobileDeviceAccessListener>

@property (atomic, assign) BOOL isRunning;
@property (nonatomic, strong) NSOperationQueue *workQueue;

@property (nonatomic, strong) NSArray *allConnectedDevices;
@property (nonatomic, strong, readwrite) MCDevice *selectedConnectedDevice;
@property (nonatomic, strong) NSString *selectedConnectedDeviceUDID;

@property (nonatomic, weak) id<MCDeviceControllerDelegate> listener;

@end

@implementation MCDeviceController

- (void)dealloc
{
    [self stopMonitor];
}

+ (instancetype)sharedInstance
{
    static MCDeviceController *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MCDeviceController alloc] init];
        sharedInstance.isRunning = NO;
    });
    return sharedInstance;
}

#pragma mark - monitor

- (void)monitorWithListener:(id<MCDeviceControllerDelegate>)listener
{
    if (self.isRunning) {
        DDLogWarn(@"device controller is already running");
        return;
    }

    [[MobileDeviceAccess singleton] setListener:self];
    self.listener = listener;

    self.isRunning = YES;

    self.workQueue = [[NSOperationQueue alloc] init];
    self.workQueue.maxConcurrentOperationCount = 1;

    DDLogInfo(@"device controller starts running");
}

- (void)stopMonitor
{
    [[MobileDeviceAccess singleton] setListener:nil];
    self.listener = nil;

    self.isRunning = NO;

    [self.workQueue cancelAllOperations];
    self.workQueue = nil;

    self.allConnectedDevices = nil;
    self.selectedConnectedDevice = nil;
    self.selectedConnectedDeviceUDID = nil;

    DDLogInfo(@"device controller stops running");
}

#pragma mark - MobileDeviceAccessListener

- (void)deviceConnected:(AMDevice*)device
{
    if (!self.isRunning) {
        return;
    }

    [self.workQueue addOperationWithBlock:^{
        if (!self.selectedConnectedDevice) {
            self.allConnectedDevices = [[MobileDeviceAccess singleton] devices];

            self.selectedConnectedDevice = [[MCDevice alloc] initWithRawDevice:self.allConnectedDevices.firstObject];
            self.selectedConnectedDeviceUDID = self.selectedConnectedDevice.udid;

            DDLogInfo(@"connect to a new device: {UDID: %@}", self.selectedConnectedDeviceUDID);

            if ([self.selectedConnectedDevice isPairedDevice]) {
                [self.listener deviceDidConnectAndPaired];

            } else {
                [self.listener deviceDidConnectButUnPaired];
            }

        } else {
            DDLogDebug(@"already connecting to a device, so ignore others connected.");
        }
    }];
}

- (void)deviceDisconnected:(AMDevice*)device
{
    if (!self.isRunning) {
        return;
    }

    [self.workQueue addOperationWithBlock:^{
        BOOL selectedDeviceStillConnected = [self.selectedConnectedDevice isConnectedDevice];

        if (selectedDeviceStillConnected) {
            DDLogDebug(@"selected device is still connected, so ignore others disconnected.");

        } else {
            DDLogInfo(@"disconnect with device: {UDID: %@}", self.selectedConnectedDeviceUDID);

            self.selectedConnectedDevice = nil;
            self.selectedConnectedDeviceUDID = nil;
            
            [self.listener deviceDidDisconnect];
        }
    }];
}

@end
