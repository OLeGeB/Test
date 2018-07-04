//
//  NSURL+Steaming.m
//  播放器
//
//  Created by 李江波 on 2017/10/18.
//  Copyright © 2017年 李江波. All rights reserved.
//

#import "NSURL+Steaming.h"

@implementation NSURL (Steaming)

- (NSURL *)steamingUrl {
    NSURLComponents *compents = [NSURLComponents componentsWithString:self.absoluteString];
    compents.scheme = @"steaming";
    return compents.URL;
}

- (NSURL *)httpUrl {
    NSURLComponents *compents = [NSURLComponents componentsWithString:self.absoluteString];
    compents.scheme = @"http";
    return compents.URL;
}
@end
