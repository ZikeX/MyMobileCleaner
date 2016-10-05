//
//  MCDevice.m
//  MyMobileCleaner
//
//  Created by GoKu on 8/18/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "MCDevice.h"
#import "LogFormatter.h"

@interface MCDevice ()

@property (nonatomic) AMDevice *rawDevice;
@property (nonatomic, readwrite, strong) NSString *udid;
@property (nonatomic, readwrite, strong) NSString *deviceName;
@property (nonatomic, readwrite, strong) NSString *deviceType;

@property (nonatomic, assign) BOOL needWaitingForPair;

@end

@implementation MCDevice

- (void)dealloc
{
    if ([self isConnectedDevice]) {
        [self stopConnection];
    }
}

- (BOOL)startConnection
{
    return YES;
}

- (BOOL)stopConnection
{
    return YES;
}

- (BOOL)startSession
{
    return YES;
}

// the connection maybe closed due to long time, so suggest to reconnect for each action.
- (BOOL)reconnectDevice
{
    [self stopConnection];

    if ([self startConnection]) {
        if ([self startSession]) {
            self.deviceType = [MCDevice deviceTypeNameForModel:self.rawDevice.productType];

            return YES;

        } else {
            DDLogError(@"[%s] failed to reconnect device: No Session", __FUNCTION__);
        }

    } else {
        DDLogError(@"[%s] failed to reconnect device: No Connection", __FUNCTION__);
    }
    
    return NO;
}

#pragma mark - connection

- (instancetype)initWithRawDevice:(AMDevice *)rawDevice
{
    self = [super init];
    if (self) {
        _rawDevice = rawDevice;
        _udid = _rawDevice.udid ?: @"";
        _deviceName = _rawDevice.deviceName ?: @"";
        _deviceType = [MCDevice deviceTypeNameForModel:_rawDevice.productType];
    }
    return self;
}

- (BOOL)isConnectedDevice
{
    return self.rawDevice.isConnected;
}

- (BOOL)isPairedDevice
{
    return YES;
}

- (void)waitingForPairWithCompleteBlock:(void(^)())completeBlock
{
    self.needWaitingForPair = YES;

    __weak typeof(self) weakSelf = self;
    // by using weak self, after self is dealloc due to disconnection of user, the following while loop will stop. ^_^

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        while (weakSelf.needWaitingForPair) {
            DDLogInfo(@"waiting for device to pair: %@", weakSelf.deviceName);

            if ([weakSelf isPairedDevice]) {

                // update device info after paired
                if ([weakSelf reconnectDevice]) {
                    if ([weakSelf startSession]) {
                        weakSelf.deviceType = [MCDevice deviceTypeNameForModel:weakSelf.rawDevice.productType];
                    }
                }

                if (completeBlock) {
                    completeBlock();
                }
                
                weakSelf.needWaitingForPair = NO;

                break;

            } else {
                [NSThread sleepForTimeInterval:0.5];
            }
        }

        DDLogInfo(@"no need to wait for device to pair");
    });
}

#pragma mark - function

- (MCDeviceDiskUsage *)diskUsage
{
    if (![self reconnectDevice]) {
        DDLogError(@"[%s] failed: Reconnect Device", __FUNCTION__);
        return nil;
    }

    NSNumber *valueTotalDiskCapacity = [self.rawDevice deviceValueForKey:kMobileDeviceTotalDiskCapacity inDomain:kMobileDeviceDiskUsageDomain];
    NSNumber *valueTotalSystemCapacity = [self.rawDevice deviceValueForKey:kMobileDeviceTotalSystemCapacity inDomain:kMobileDeviceDiskUsageDomain];
    NSNumber *valueTotalSystemAvailable = [self.rawDevice deviceValueForKey:kMobileDeviceTotalSystemAvailable inDomain:kMobileDeviceDiskUsageDomain];
    NSNumber *valueTotalDataCapacity = [self.rawDevice deviceValueForKey:kMobileDeviceTotalDataCapacity inDomain:kMobileDeviceDiskUsageDomain];
    NSNumber *valueTotalDataAvailable = [self.rawDevice deviceValueForKey:kMobileDeviceTotalDataAvailable inDomain:kMobileDeviceDiskUsageDomain];
    NSNumber *valueAmountDataReserved = [self.rawDevice deviceValueForKey:kMobileDeviceAmountDataReserved inDomain:kMobileDeviceDiskUsageDomain];
    NSNumber *valueAmountDataAvailable = [self.rawDevice deviceValueForKey:kMobileDeviceAmountDataAvailable inDomain:kMobileDeviceDiskUsageDomain];

    /*
    kTotalDiskCapacity = kTotalSystemCapacity + kTotalDataCapacity
    kTotalDataAvailable = kAmountDataReserved + kAmountDataAvailable
    total for user     = kTotalDiskCapacity
    used for user      = (kTotalSystemCapacity - kTotalSystemAvailable) + (kTotalDataCapacity - kTotalDataAvailable)
    free for user      = kAmountDataAvailable
    reserved for user  = total - used - free = kTotalSystemAvailable + kAmountDataReserved
    */

    if (valueTotalDiskCapacity == NULL ||
        valueTotalSystemCapacity == NULL ||
        valueTotalSystemAvailable == NULL ||
        valueTotalDataCapacity == NULL ||
        valueTotalDataAvailable == NULL ||
        valueAmountDataReserved == NULL ||
        valueAmountDataAvailable == NULL) {

        DDLogError(@"[%s] failed: Copy Value Error", __FUNCTION__);
        return nil;
    }

    MCDeviceDiskUsage *disk = [[MCDeviceDiskUsage alloc] init];
    disk.totalDiskCapacity = valueTotalDiskCapacity;
    disk.totalDiskUsed = @((valueTotalSystemCapacity.unsignedIntegerValue - valueTotalSystemAvailable.unsignedIntegerValue) + (valueTotalDataCapacity.unsignedIntegerValue - valueTotalDataAvailable.unsignedIntegerValue));
    disk.totalDiskFree = valueAmountDataAvailable;
    disk.totalDiskReserved = @(valueTotalSystemAvailable.unsignedIntegerValue + valueAmountDataReserved.unsignedIntegerValue);

    return disk;
}

- (void)scanCrashLogSuccessBlock:(void(^)(NSArray *crashLogs))successBlock
                     updateBlock:(void(^)(NSUInteger totalItemCount, MCDeviceCrashLogItem *currentScannedItem))updateBlock
                    failureBlock:(void(^)())failureBlock
{
    DDLogInfo(@"===== start to scan crash log =====");

    if (![self reconnectDevice]) {
        DDLogError(@"[%s] failed: Reconnect Device", __FUNCTION__);
        if (failureBlock) {
            failureBlock();
        }
        return;
    }

    AFCCrashLogDirectory *crashLogDirectory = [self.rawDevice newAFCCrashLogDirectory];
    if (!crashLogDirectory) {
        DDLogError(@"[%s] failed: No Service", __FUNCTION__);
        if (failureBlock) {
            failureBlock();
        }
        return;
    }

    NSMutableArray *crashLogs = [NSMutableArray array];

    NSArray *dirContents = [crashLogDirectory directoryContents:@""];
    for (NSString *path in dirContents) {
        MCDeviceCrashLogItem *item = [[MCDeviceCrashLogItem alloc] init];
        item.path = path;

        NSDictionary *info = [crashLogDirectory getFileInfo:path];
        if (info) {
            item.isDir = [info[kMobileDeviceFileInfo_st_ifmt] isEqualToString:@"S_IFDIR"];
            MCDeviceCrashLogSearchedItem *searchedItem = [self infoOfItemWithFullPath:path afcDirectoryAccess:crashLogDirectory];
            item.totalSize = @(searchedItem.totalSize);
            item.allFiles = searchedItem.allFiles;

            if (updateBlock) {
                updateBlock(dirContents.count, item);
            }

            [crashLogs addObject:item];
        }
    }

    if (successBlock) {
        successBlock(crashLogs);
    }
}

- (void)cleanCrashLog:(NSArray *)crashLogs
         successBlock:(void(^)())successBlock
          updateBlock:(void(^)(NSUInteger currentItemIndex))updateBlock
         failureBlock:(void(^)())failureBlock
{
    DDLogInfo(@"===== start to clean crash log =====");

    if (crashLogs.count == 0) {
        if (successBlock) {
            successBlock();
        }
        return;
    }

    if (![self reconnectDevice]) {
        DDLogError(@"[%s] failed: Reconnect Device", __FUNCTION__);
        if (failureBlock) {
            failureBlock();
        }
        return;
    }
    
    AFCCrashLogDirectory *crashLogDirectory = [self.rawDevice newAFCCrashLogDirectory];
    if (!crashLogDirectory) {
        DDLogError(@"[%s] failed: No Service", __FUNCTION__);
        if (failureBlock) {
            failureBlock();
        }
        return;
    }
    
    for (NSUInteger i = 0; i < crashLogs.count; ++i) {
        MCDeviceCrashLogItem *item = crashLogs[i];

        if ([crashLogDirectory fileExistsAtPath:item.path]) {
            if (item.isDir) {
                NSArray *allContents = [crashLogDirectory recursiveDirectoryContents:item.path];
                for (NSString *content in allContents) {
                    if (![content hasSuffix:@"/"]) { // not dir
                        BOOL ret = [crashLogDirectory unlink:content];
                        if (!ret) {
                            DDLogWarn(@"[%s] warning: failed to clean %@", __FUNCTION__, content);
                        }
                    }
                }
            } else {
                BOOL ret = [crashLogDirectory unlink:item.path];
                if (!ret) {
                    DDLogWarn(@"[%s] warning: failed to clean %@", __FUNCTION__, item.path);
                }
            }

        } else {
            DDLogWarn(@"[%s] warning: file not exist %@", __FUNCTION__, item.path);
        }

        if (updateBlock) {
            updateBlock(i);
        }
    }

    if (successBlock) {
        successBlock();
    }
}

#pragma mark - inner

- (MCDeviceCrashLogSearchedItem *)infoOfItemWithFullPath:(NSString *)path
                                      afcDirectoryAccess:(AFCCrashLogDirectory *)crashLogDirectory
{
    MCDeviceCrashLogSearchedItem *searchedItem = [[MCDeviceCrashLogSearchedItem alloc] init];
    searchedItem.totalSize = 0;
    searchedItem.allFiles = [NSMutableArray array];

    NSDictionary *info = [crashLogDirectory getFileInfo:path];
    if (info) {
        NSUInteger size = [info[kMobileDeviceFileInfo_st_size] unsignedIntegerValue];
        searchedItem.totalSize += size;

        BOOL isDir = [info[kMobileDeviceFileInfo_st_ifmt] isEqualToString:@"S_IFDIR"];
        if (isDir) {
            NSArray *dirContents = [crashLogDirectory directoryContents:path];
            for (NSString *subPath in dirContents) {
                NSString *newPath = [path stringByAppendingPathComponent:subPath];
                MCDeviceCrashLogSearchedItem *subSearchedItem = [self infoOfItemWithFullPath:newPath afcDirectoryAccess:crashLogDirectory];
                searchedItem.totalSize += subSearchedItem.totalSize;
                [searchedItem.allFiles addObjectsFromArray:subSearchedItem.allFiles];
            }

        } else {
            MCDeviceCrashLogFileInfo *fileInfo = [[MCDeviceCrashLogFileInfo alloc] init];
            fileInfo.filePath = path;
            fileInfo.fileSize = size;
            [searchedItem.allFiles addObject:fileInfo];
        }
    }

    return searchedItem;
}

- (AMDevice *)findDeviceFromUDID:(NSString *)udid
{
    NSArray *devices = [[MobileDeviceAccess singleton] devices];
    AMDevice *foundDevice = nil;

    if (devices.count) {
        for (AMDevice *device in devices) {
            NSString *deviceUDID = device.udid;
            if ([deviceUDID isEqualToString:udid]) {
                foundDevice = device;
                break;
            }
        }

        if (!foundDevice) {
            DDLogError(@"[%s] failed: No device found with {UDID: %@}", __FUNCTION__, udid);
        }

    } else {
        DDLogError(@"[%s] failed: No Devices", __FUNCTION__);
    }
    
    return foundDevice;
}

#pragma mark - device type name

+ (NSString *)deviceTypeNameForModel:(NSString *)model
{
    // iPhone
    if ([model isEqualToString:@"iPhone8,4"])   return @"iPhone SE";
    if ([model isEqualToString:@"iPhone8,2"])   return @"iPhone 6S";
    if ([model isEqualToString:@"iPhone8,1"])   return @"iPhone 6S Plus";
    if ([model isEqualToString:@"iPhone7,2"])   return @"iPhone 6";
    if ([model isEqualToString:@"iPhone7,1"])   return @"iPhone 6 Plus";
    if ([model isEqualToString:@"iPhone6,2"])   return @"iPhone 5S";
    if ([model isEqualToString:@"iPhone6,1"])   return @"iPhone 5S";
    if ([model isEqualToString:@"iPhone5,4"])   return @"iPhone 5C";
    if ([model isEqualToString:@"iPhone5,3"])   return @"iPhone 5C";
    if ([model isEqualToString:@"iPhone5,2"])   return @"iPhone 5";
    if ([model isEqualToString:@"iPhone5,1"])   return @"iPhone 5";
    if ([model isEqualToString:@"iPhone4,1"])   return @"iPhone 4S";
    if ([model isEqualToString:@"iPhone3,3"])   return @"iPhone 4";
    if ([model isEqualToString:@"iPhone3,1"])   return @"iPhone 4";
    if ([model isEqualToString:@"iPhone2,1"])   return @"iPhone 3GS";
    if ([model isEqualToString:@"iPhone1,2"])   return @"iPhone 3G";
    if ([model isEqualToString:@"iPhone1,1"])   return @"iPhone 1G";

    // Apple Watch
    if ([model isEqualToString:@"Watch1,2"])    return @"Apple Watch";
    if ([model isEqualToString:@"Watch1,1"])    return @"Apple Watch";

    // iPad Pro
    if ([model isEqualToString:@"iPad6,8"])     return @"iPad Pro";
    if ([model isEqualToString:@"iPad6,7"])     return @"iPad Pro (WiFi)";
    if ([model isEqualToString:@"iPad6,4"])     return @"iPad Pro";
    if ([model isEqualToString:@"iPad6,3"])     return @"iPad Pro (WiFi)";

    // iPad Air
    if ([model isEqualToString:@"iPad5,4"])     return @"iPad Air 2";
    if ([model isEqualToString:@"iPad5,3"])     return @"iPad Air 2 (WiFi)";
    if ([model isEqualToString:@"iPad4,3"])     return @"iPad Air";
    if ([model isEqualToString:@"iPad4,2"])     return @"iPad Air";
    if ([model isEqualToString:@"iPad4,1"])     return @"iPad Air (WiFi)";

    // iPad Mini
    if ([model isEqualToString:@"iPad4,9"])     return @"iPad Mini 3";
    if ([model isEqualToString:@"iPad4,8"])     return @"iPad Mini 3";
    if ([model isEqualToString:@"iPad4,7"])     return @"iPad Mini 3 (WiFi)";
    if ([model isEqualToString:@"iPad4,5"])     return @"iPad Mini Retina";
    if ([model isEqualToString:@"iPad4,4"])     return @"iPad Mini Retina (WiFi)";
    if ([model isEqualToString:@"iPad2,7"])     return @"iPad Mini";
    if ([model isEqualToString:@"iPad2,6"])     return @"iPad Mini";
    if ([model isEqualToString:@"iPad2,5"])     return @"iPad Mini (WiFi)";

    // iPad
    if ([model isEqualToString:@"iPad3,6"])     return @"iPad 4";
    if ([model isEqualToString:@"iPad3,5"])     return @"iPad 4";
    if ([model isEqualToString:@"iPad3,4"])     return @"iPad 4 (WiFi)";
    if ([model isEqualToString:@"iPad3,3"])     return @"iPad 3";
    if ([model isEqualToString:@"iPad3,2"])     return @"iPad 3";
    if ([model isEqualToString:@"iPad3,1"])     return @"iPad 3 (WiFi)";
    if ([model isEqualToString:@"iPad2,4"])     return @"iPad 2 (WiFi)";
    if ([model isEqualToString:@"iPad2,3"])     return @"iPad 2";
    if ([model isEqualToString:@"iPad2,2"])     return @"iPad 2";
    if ([model isEqualToString:@"iPad2,1"])     return @"iPad 2 (WiFi)";
    if ([model isEqualToString:@"iPad1,1"])     return @"iPad";

    // iPod
    if ([model isEqualToString:@"iPod7,1"])     return @"iPod Touch 6G";
    if ([model isEqualToString:@"iPod5,1"])     return @"iPod Touch 5G";
    if ([model isEqualToString:@"iPod4,1"])     return @"iPod Touch 4G";
    if ([model isEqualToString:@"iPod3,1"])     return @"iPod Touch 3G";
    if ([model isEqualToString:@"iPod2,1"])     return @"iPod Touch 2G";
    if ([model isEqualToString:@"iPod1,1"])     return @"iPod Touch 1G";

    // Simulator
    if ([model isEqualToString:@"x86_64"])      return @"iOS Simulator";
    if ([model isEqualToString:@"i386"])        return @"iOS Simulator";

    return @"Unknown Device";
}

@end
