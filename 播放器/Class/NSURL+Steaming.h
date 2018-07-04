//
//  NSURL+Steaming.h
//  播放器
//
//  Created by 李江波 on 2017/10/18.
//  Copyright © 2017年 李江波. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (Steaming)
- (NSURL *)steamingUrl;

- (NSURL *)httpUrl;
@end
