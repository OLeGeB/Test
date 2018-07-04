//
//  BORemotePlayer.m
//  播放器
//
//  Created by 李江波 on 2017/10/11.
//  Copyright © 2017年 李江波. All rights reserved.
//

#import "BORemotePlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "BORemoteResourceLoaderDelegate.h"
#import "NSURL+Steaming.h"

@interface BORemotePlayer ()
{
    BOOL _isUserPause;
}

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) BORemoteResourceLoaderDelegate *remoteResourceLoaderDelegate;
@end

static BORemotePlayer *_shareInstance;
@implementation BORemotePlayer

+(instancetype)shareInstance {
    if (_shareInstance == nil) {
        _shareInstance = [[BORemotePlayer alloc] init];
    }
    return _shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!_shareInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _shareInstance = [super allocWithZone:zone];
        });
    }
    return _shareInstance;
}

- (void)playWithURL:(NSURL *)url isCache:(BOOL)isCache{
    NSURL *currentUrl = [(AVURLAsset *)self.player.currentItem.asset URL];
    if ([url isEqual:currentUrl]) {
        NSLog(@"当前播放任务已经存在");
        [self resume];
        return;
    }
    // 创建一个播放器对象
    // 如果我们使用这样的方法，去播放远程音频
    // 这个方法，已经帮我们封装了三个步骤
    // 1.资源的请求
    // 2.资源的组织
    // 3.给播放器，资源的播放
    // 如果资源加载比较慢，有可能，会造成调用了play方法，但是当前并没有播放音频
    _url = url;
    if (isCache) {
        url = [url steamingUrl];
    }
   
    // 1.资源的请求
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    // 关于网络音频的请求，是通过这个对象，调用代理的相关方法，进行加载的
    // 拉结加载的请求，只需要，重新修改它的代理方法就可以
    self.remoteResourceLoaderDelegate = [BORemoteResourceLoaderDelegate new];
    [asset.resourceLoader setDelegate:self.remoteResourceLoaderDelegate queue:dispatch_get_main_queue()];
    if (self.player.currentItem) {
//        [self removeObserver:self.player.currentItem forKeyPath:@"status"];
        [self removeObserver];
    }
    
    // 2.资源的组织
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    // 资源的组织者，告诉我们资源准备好了之后，我们再播放
    // AVPlayerItemStatus status
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];// 播放完成的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playInterput) name:AVPlayerItemPlaybackStalledNotification object:nil];// 播放被打断
    // 3.资源的播放
    self.player = [AVPlayer playerWithPlayerItem:item];
}

#pragma mark - 外界接口
- (void)pause {
    [self.player pause];
    
    _isUserPause = YES;
    if (self.player) {
        self.state = BORemotePlayerStatePause;
    }
}

- (void)resume {
    [self.player play];
    
    _isUserPause = NO;
    if (self.player && self.player.currentItem.playbackLikelyToKeepUp) {
        self.state = BORemotePlayerStatePlaying;
    }
}

- (void)stop {
    [self.player pause];
    self.player = nil;
    if (self.player) {
        self.state = BORemotePlayerStateStopped;
    }
}

// 快进多少秒,可以为负数
- (void)seekWithTimeDiffer:(NSTimeInterval)timeDiffer {
    
    // 1.当前音频资源的总时长
    NSTimeInterval totalTimeSec = [self totalTime];
    // 2.当前音频，已经播放的时长
    NSTimeInterval playTimeSec = [self currentTime];
    playTimeSec += timeDiffer;
    
    [self seekWithProgress:playTimeSec / totalTimeSec];
    
}

//快进到固定的百分比
- (void)seekWithProgress:(float)progress {
    if (progress <= 0 || progress > 1) {
        return;
    }
    // 可以指定时间节点去播放
    // 时间：CMTime:影片时间
    // 影片时间 -> 秒
    // 秒 -> 影片时间
    
    // 1.当前音频资源的总时长
    CMTime totalTime = self.player.currentItem.duration;
    
    // 2.当前音频，已经播放的时间
    
    NSTimeInterval totalSec = CMTimeGetSeconds(totalTime);
    NSTimeInterval playTimeSec = totalSec * progress;
    CMTime currentTime = CMTimeMake(playTimeSec, 1);
    [self.player seekToTime:currentTime completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"确定加载这个时间点的音频资源");
        }else {
            // 作用于连续拖动几次，上次的将被取消
            NSLog(@"取消加载这个时间点的音频资源");
        }
    }];

}
#pragma mark - 由于state是只读的，需要重写set方法
- (void)setState:(BORemotePlayerState)state {
    _state = state;
    
    // 如果需要告知外界相关的事件，在这儿
}

#pragma mark - 移除监听
- (void)removeObserver {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

- (void)setRate:(float)rate {
    [self.player setRate:rate];
}
- (float)rate {
    return self.player.rate;
}
#pragma mark - 设置是否静音
- (void)setMuted:(BOOL)muted {
    [self.player setMuted:muted];
}
- (BOOL)muted {
    return self.player.muted;
}
- (void)setVolume:(float)volume {
    if (volume < 0 || volume > 1) {
        return;
    }
    
    if (volume > 0) {
        [self setMuted:NO];
    }
    [self.player setVolume:volume];
}
- (float)volume {
    return self.player.volume;
}
#pragma mark - 事件、数据
- (NSTimeInterval)totalTime {
    // 1.当前音频资源的总时长
    CMTime totalTime = self.player.currentItem.duration;
    NSTimeInterval totalTimeSec = CMTimeGetSeconds(totalTime);
    if (isnan(totalTimeSec)) {
        return 0;
    }
    return totalTimeSec;
}

- (NSString *)totalTimeFormat {
    NSString *totalString = [NSString stringWithFormat:@"%02zd:%02zd", (int)self.totalTime / 60, (int)self.totalTime % 60];
    return totalString;
}

- (NSTimeInterval)currentTime {
    CMTime playTime = self.player.currentItem.currentTime;
    NSTimeInterval playTimeSec = CMTimeGetSeconds(playTime);
    if (isnan(playTimeSec)) {
        return 0;
    }
    return playTimeSec;
}

- (NSString *)currentTimeFormat {
    return [NSString stringWithFormat:@"%02zd:%02zd", (int)self.currentTime / 60, (int)self.currentTime % 60];
}

- (float)progress {
    if (self.totalTime == 0) {
        return 0;
    }
    return self.currentTime / self.totalTime;
}

- (float)loadDataProgress {
    
    if (self.totalTime == 0) {
        return 0;
    }
    CMTimeRange timeRange = [[self.player.currentItem loadedTimeRanges].lastObject CMTimeRangeValue];
    
    CMTime loadTime = CMTimeAdd(timeRange.start, timeRange.duration);
    NSTimeInterval loadTimeSec = CMTimeGetSeconds(loadTime);
    
    return loadTimeSec / self.totalTime;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context     {
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        
        if (status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"资源准备好了，准备播放吧");
            [self resume];
        }else {
            NSLog(@"状态未知");
            self.state = BORemotePlayerStateFailed;
        }
    
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        BOOL ptk = [change[NSKeyValueChangeNewKey] boolValue];
        if (ptk) {
            NSLog(@"当前的资源，准备的已经足够播放了");
            // 用户的手动暂停的优先级最高
            if (!_isUserPause) {
                [self resume];
            }else {
                
            }
            
        }else {
            NSLog(@"资源还不够，正在加载过程当中");
            self.state = BORemotePlayerStateLoading;
        }
    }
}

#pragma mark - 当前播放完成
- (void)playEnd {
    NSLog(@"播放完成");
    self.state = BORemotePlayerStateStopped;
}

#pragma mark - 播放被打断
- (void)playInterput {
    // 来电话，资源加载跟不上
    NSLog(@"播放被打断了");
    self.state = BORemotePlayerStatePause;
}
@end
