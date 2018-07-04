//
//  BORemoteAudioFile.h
//  播放器
//
//  Created by 李江波 on 2017/10/24.
//  Copyright © 2017年 李江波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BORemoteAudioFile : NSObject

/**
 根据url，获取相应的本地，缓存路径，下载完成的路径
 */
+ (NSString *)cacheFilePath:(NSURL *)url;

+ (NSString *)tmpFilePath:(NSURL *)url;

+ (long long)cacheFileSize:(NSURL *)url;
+ (long long)tmpFileSize:(NSURL *)url;

+ (BOOL)cacheFileExists:(NSURL *)url;
+ (BOOL)tmpFileExists:(NSURL *)url;

+ (void)clearTmpFile:(NSURL *)url;

/**获取文件扩展名*/
+ (NSString *)contentType:(NSURL *)url;

+ (void)moveTmpPathToCachePath:(NSURL *)url;
@end
