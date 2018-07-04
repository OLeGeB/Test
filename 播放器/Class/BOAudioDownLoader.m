//
//  BOAudioDownLoader.m
//  播放器
//
//  Created by 李江波 on 2017/10/24.
//  Copyright © 2017年 李江波. All rights reserved.
//

#import "BOAudioDownLoader.h"
#import "BORemoteAudioFile.h"

// 下载某一个区间的数据

@interface BOAudioDownLoader()<NSURLSessionDataDelegate>
{
    NSURL *_currentUrl;
}
@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSOutputStream *outputStream;

@end

@implementation BOAudioDownLoader

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset {
    _currentUrl = url;
    
    [self cancelAndClean];
    
    // 请求的是某一个区间的数据 Range
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
}

- (void)cancelAndClean {
    [self.session invalidateAndCancel];
    self.session = nil;
    
    // 清空本地已经存储的临时缓存
    [BORemoteAudioFile clearTmpFile:_currentUrl];
    self.loadSize = 0;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    // 1.从Content-Length 取出来
    // 2.如果Content-Range有，应该从Content-Range里面获取
    self.totalSize = [response.allHeaderFields[@"Content-Length"] longLongValue];
    NSString *contentRangeStr = response.allHeaderFields[@"Content-Range"];
    if (contentRangeStr.length != 0) {
        self.totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    }
    
    self.mimeType = response.MIMEType;
    
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:[BORemoteAudioFile tmpFilePath:_currentUrl] append:YES];
    [self.outputStream open];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    self.loadSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    
    if ([self.delegate respondsToSelector:@selector(downLoading)]) {
        [self.delegate downLoading];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error == nil) {
        if ([BORemoteAudioFile tmpFileSize:_currentUrl] == self.totalSize) {
            [BORemoteAudioFile moveTmpPathToCachePath:_currentUrl];
        }
    }else {
        NSLog(@"有错误"); 
    }
}
@end
