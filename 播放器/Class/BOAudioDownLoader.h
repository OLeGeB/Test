//
//  BOAudioDownLoader.h
//  播放器
//
//  Created by 李江波 on 2017/10/24.
//  Copyright © 2017年 李江波. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BOAudioDownLoaderDelegate <NSObject>

- (void)downLoading;
@end

@interface BOAudioDownLoader : NSObject

@property (nonatomic, weak) id<BOAudioDownLoaderDelegate> delegate;
@property (nonatomic, assign) long long totalSize;
@property (nonatomic, assign) long long offset;
@property (nonatomic, assign) long long loadSize;
@property (nonatomic, strong) NSString *mimeType;
- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset;
@end
