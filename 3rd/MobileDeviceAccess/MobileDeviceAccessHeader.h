//
//  MobileDeviceAccessHeader.h
//  MyMobileCleaner
//
//  Created by GoKu on 10/5/16.
//  Copyright © 2016 GoKuStudio. All rights reserved.
//

#ifndef MobileDeviceAccessHeader_h
#define MobileDeviceAccessHeader_h


#define kMobileDeviceDiskUsageDomain                @"com.apple.disk_usage"
#define kMobileDeviceTotalDiskCapacity              @"TotalDiskCapacity"
#define kMobileDeviceTotalSystemCapacity            @"TotalSystemCapacity"
#define kMobileDeviceTotalSystemAvailable           @"TotalSystemAvailable"
#define kMobileDeviceTotalDataCapacity              @"TotalDataCapacity"
#define kMobileDeviceTotalDataAvailable             @"TotalDataAvailable"
#define kMobileDeviceAmountDataReserved             @"AmountDataReserved"
#define kMobileDeviceAmountDataAvailable            @"AmountDataAvailable"


#define kMobileDeviceFileInfo_st_ifmt       @"st_ifmt" // file type
//                                          "S_IFREG" - regular file
//                                          "S_IFDIR" - directory
//                                          "S_IFCHR" - character device
//                                          "S_IFBLK" - block device
//                                          "S_IFLNK" - symbolic link (see LinkTarget)
#define kMobileDeviceFileInfo_st_blocks     @"st_blocks" // number of disk blocks occupied by file
#define kMobileDeviceFileInfo_st_nlink      @"st_nlink" // number of "links" occupied by file
#define kMobileDeviceFileInfo_st_size       @"st_size" // number of "bytes" in file
#define kMobileDeviceFileInfo_LinkTarget    @"LinkTarget" // target of symbolic link (only if st_ifmt="S_IFLNK")
#define kMobileDeviceFileInfo_st_birthtime  @"st_birthtime" // time that file was created
#define kMobileDeviceFileInfo_st_mtime      @"st_mtime" // time that file was modified


#import "MobileDeviceAccess.h"

#endif /* MobileDeviceAccessHeader_h */
