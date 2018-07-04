//
//  BORemoteAudioFile.m
//  播放器
//
//  Created by 李江波 on 2017/10/24.
//  Copyright © 2017年 李江波. All rights reserved.
//

#import "BORemoteAudioFile.h"
#import <MobileCoreServices/MobileCoreServices.h>
#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmpPath NSTemporaryDirectory()
@implementation BORemoteAudioFile

// 下载完成 -> cache + 文件名称
+ (NSString *)cacheFilePath:(NSURL *)url {
    return [kCachePath stringByAppendingPathComponent:url.lastPathComponent];
}
+ (NSString *)tmpFilePath:(NSURL *)url {
    
    return [kTmpPath stringByAppendingPathComponent:url.lastPathComponent];
}

+ (long long)tmpFileSize:(NSURL *)url {
    if (![self tmpFileExists:url]) {
        return 0;
    }
    // 获取文件路径
    NSString *path = [self tmpFilePath:url];
    NSDictionary *fileInfoDict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfoDict[NSFileSize] longLongValue];
}

+ (BOOL)tmpFileExists:(NSURL *)url {
    NSString *path = [self tmpFilePath:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (long long)cacheFileSize:(NSURL *)url {
    
    // 1.2计算文件路径对应的文件大小
    if (![self cacheFileExists:url]) {
        return 0;
    }
    
    // 1.1获取文件路径
    NSString *path = [self cacheFilePath:url];
    NSDictionary *fileInfoDict = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfoDict[NSFileSize] longLongValue];
}
// 下载中 -> tmp + 文件名称
+ (BOOL)cacheFileExists:(NSURL *)url {
    NSString *path = [self cacheFilePath:url];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (NSString *)contentType:(NSURL *)url {
    NSString *path = [self cacheFilePath:url];
    NSString *fileExtension = path.pathExtension;
    
    CFStringRef contentTypeCF = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(fileExtension), NULL);
    
    NSString *contentType = CFBridgingRelease(contentTypeCF);
    return contentType;
}

+ (void)moveTmpPathToCachePath:(NSURL *)url {
    [[NSFileManager defaultManager] moveItemAtPath:[self tmpFilePath:url] toPath:[self cacheFilePath:url] error:nil];
}

+ (void)clearTmpFile:(NSURL *)url {
    NSString *tmpPath = [self tmpFilePath:url];
    BOOL isDirectory = YES;
    BOOL isEX = [[NSFileManager defaultManager] fileExistsAtPath:kTmpPath isDirectory:&isDirectory];
    if (isEX && !isDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    }
   
}
@end
