//
//  BORemotePlayer.h
//  播放器
//
//  Created by 李江波 on 2017/10/11.
//  Copyright © 2017年 李江波. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BORemotePlayerState) {
    BORemotePlayerStateUnknown = 0,//未知
    BORemotePlayerStateLoading = 1,//正在加载
    BORemotePlayerStatePlaying = 2,//正在播放
    BORemotePlayerStateStopped = 3,// 停止
    BORemotePlayerStatePause = 4,//暂停
    BORemotePlayerStateFailed = 5,// 失败(比如没有网络)
};
@interface BORemotePlayer : NSObject

+ (instancetype)shareInstance;

- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache;

- (void)pause;

- (void)resume;

- (void)stop;

- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer;

- (void)seekWithProgress:(float)progress;


// 数据、事件
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) float volume;
@property (nonatomic, assign) float rate;
@property (nonatomic, assign, readonly) NSTimeInterval totalTime;
@property (nonatomic, copy) NSString *totalTimeFormat;
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
@property (nonatomic, copy) NSString *currentTimeFormat;
@property (nonatomic, assign, readonly) float progress;

@property (nonatomic, assign, readonly) float loadDataProgress;// 缓存进度

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, assign, readonly) BORemotePlayerState state;
@end
