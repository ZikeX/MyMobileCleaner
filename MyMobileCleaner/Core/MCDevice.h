//
//  MCDevice.h
//  MyMobileCleaner
//
//  Created by GoKu on 8/18/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobileDeviceAccessHeader.h"
#import "MCDeviceInfoHub.h"

@interface MCDevice : NSObject

@property (nonatomic, readonly, strong) NSString *udid;
@property (nonatomic, readonly, strong) NSString *deviceName;
@property (nonatomic, readonly, strong) NSString *deviceType; // need device paired

+ (NSString *)deviceTypeNameForModel:(NSString *)model;

- (instancetype)initWithRawDevice:(AMDevice *)rawDevice;

- (BOOL)isConnectedDevice;
- (BOOL)isPairedDevice;
- (void)waitingForPairWithCompleteBlock:(void(^)(void))completeBlock;

- (MCDeviceDiskUsage *)diskUsage;

- (void)scanCrashLogSuccessBlock:(void(^)(NSArray *crashLogs))successBlock // array of MCDeviceCrashLogItem
                     updateBlock:(void(^)(NSUInteger totalItemCount, MCDeviceCrashLogItem *currentScannedItem))updateBlock
                    failureBlock:(void(^)(void))failureBlock;
- (void)cleanCrashLog:(NSArray *)crashLogs // array of MCDeviceCrashLogItem
         successBlock:(void(^)(void))successBlock
          updateBlock:(void(^)(NSUInteger currentItemIndex))updateBlock
         failureBlock:(void(^)(void))failureBlock;

@end
