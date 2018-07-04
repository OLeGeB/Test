//
//  BORemoteResourceLoaderDelegate.m
//  播放器
//
//  Created by 李江波 on 2017/10/18.
//  Copyright © 2017年 李江波. All rights reserved.
//

#import "BORemoteResourceLoaderDelegate.h"
#import "BORemoteAudioFile.h"
#import "BOAudioDownLoader.h"
#import "NSURL+Steaming.h"

@interface BORemoteResourceLoaderDelegate()<BOAudioDownLoaderDelegate>
@property (nonatomic, strong) BOAudioDownLoader *downLoader;

@property (nonatomic, strong) NSMutableArray *loadingRequestM;
@end

@implementation BORemoteResourceLoaderDelegate

- (NSMutableArray *)loadingRequestM {
    if (_loadingRequestM == nil) {
        _loadingRequestM = [NSMutableArray array];
    }
    return _loadingRequestM;
}

- (BOAudioDownLoader *)downLoader {
    if (_downLoader == nil) {
        _downLoader = [[BOAudioDownLoader alloc] init];
        _downLoader.delegate = self;
    }
    return _downLoader;
}

// 当外界，需要播放一段音频资源时，会抛一个请求，给这个对象
// 这个对象，到时候，只需要根据请求信息，抛数据给外界
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"%@", loadingRequest);
    
    // 1.判断，本地有没有该音频资源的缓存文件，如果有 -> 直接根据本地缓存，向外界响应的数据(3个步骤) return
    // 1.拿到路径
    // 2.判断有没
    NSURL *url = [loadingRequest.request.URL httpUrl];
    long long requestOffset =loadingRequest.dataRequest.requestedOffset;
    long long currentOffest = loadingRequest.dataRequest.currentOffset;
    if (requestOffset != currentOffest) {
        requestOffset = currentOffest;
    }
    if ([BORemoteAudioFile cacheFileExists:url]) {
        [self handleLoadingRequest:loadingRequest];
        return YES;
    }
    
    // 记录所有的请求
    [self.loadingRequestM addObject:loadingRequest];
    
    // 2.判断有没有正在下载
    if (self.downLoader.loadSize == 0) {
        
        [self.downLoader downLoadWithURL:url offset:requestOffset];
        return YES;
    }
    
    // 3.判断当前是否需要重新下载
    // 3.1当资源请求，开始点<下载的开始点
    // 3.2 当资源请求，开始点 > 下载的开始点
    
    if (requestOffset < self.downLoader.offset || requestOffset > self.downLoader.offset + self.downLoader.loadSize) {
        [self.downLoader downLoadWithURL:url offset:requestOffset];
        return YES;
    }
    
    // 开始处理请求(在下载过程，需要不断的判断)
    [self handleAllLoadingRequest];
    
    // 大步骤下载
    // 2.判断当前有没有在下载，如果没有，下载 return
    
    // 3.当前有下载 -> 判断，是否需要重新下载，如果是，return
    
    // 4.处理所有请求，并且，在下载的过程当中，不断地请求处理
    
    // 如何根据请求信息，返回给外界数据
    
 
    return YES;
}

// 取消请求
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.loadingRequestM removeObject:loadingRequest];
}

- (void)downLoading {
    [self handleAllLoadingRequest];
}

- (void)handleAllLoadingRequest {
    NSLog(@"在这里不断的处理请求");
    
    NSMutableArray *deleteRequests = [NSMutableArray array];
    
    for (AVAssetResourceLoadingRequest *loadingRequest in self.loadingRequestM) {
        // 1.填充内容信息头
        NSURL *url = loadingRequest.request.URL;
        long long totalSize = self.downLoader.totalSize;
        loadingRequest.contentInformationRequest.contentLength = totalSize;
        
        NSString *contentType = self.downLoader.mimeType    ;
        loadingRequest.contentInformationRequest.contentType = contentType;
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        // 2.填充数据
        NSData *data = [NSData dataWithContentsOfFile:[BORemoteAudioFile tmpFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        // 在加载完的一刹那，会造成一部分数据损失，作出容错处理
        if (data == nil) {
            data = [NSData dataWithContentsOfFile:[BORemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
        }
        long long requestOffset = loadingRequest.dataRequest.requestedOffset;
        long long currentOffset = loadingRequest.dataRequest.currentOffset;
        if (requestOffset != currentOffset) {
            requestOffset = currentOffset;
        }
        NSInteger requesetLength = loadingRequest.dataRequest.requestedLength;
        
        long long responseOffset = requestOffset - self.downLoader.offset;
        long long responseLength = MIN(self.downLoader.offset + self.downLoader.loadSize - requestOffset, requesetLength);
        
        NSData *subdata = [data subdataWithRange:NSMakeRange(responseOffset, responseLength)];
        [loadingRequest.dataRequest respondWithData:subdata];
        
        // 3.完成请求(必须把所有的关于这个请求的区间数据，都返回完之后，才能完成这个请求)
        if (requesetLength == responseLength) {
            
            [loadingRequest finishLoading];
            [deleteRequests addObject:loadingRequest];
        }
        
    }
    
    [self.loadingRequestM removeObjectsInArray:deleteRequests];
    
}

// 处理本地已经下载好的资源文件
#pragma mark - 私有方法
- (void)handleLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    // 1.填充相应的信息头信息
    //    contentLength
    //   contentType
    //    byteRangeAccessSupported
   
    // 计算总大小
    
    NSURL *url = loadingRequest.request.URL;
    long long totalSize = [BORemoteAudioFile cacheFileSize:url];
    loadingRequest.contentInformationRequest.contentLength = totalSize;
    
    NSString *contentType = [BORemoteAudioFile contentType:url];
    loadingRequest.contentInformationRequest.contentType = contentType;
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    
    // 2.相应数据给外界
    NSData *data = [NSData dataWithContentsOfFile:[BORemoteAudioFile cacheFilePath:url] options:NSDataReadingMappedIfSafe error:nil];
    
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    NSInteger requesetLength = loadingRequest.dataRequest.requestedLength;
    
    NSData *subData = [data subdataWithRange:NSMakeRange(requestOffset, requesetLength)];
    
    [loadingRequest.dataRequest respondWithData:subData];
    
    // 完成本次请求(一旦，所有的数据都给完了，才能调用完成请求方法)
    [loadingRequest finishLoading];
}
@end
