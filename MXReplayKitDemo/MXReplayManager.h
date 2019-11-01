//
//  MXReplayManager.h
//  MXReplayKitDemo
//
//  Created by 66-admin on 2019/11/1.
//  Copyright © 2019 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXReplayManager : NSObject

+ (void)mx_getPHAuthorizationStatusBlock:(void(^_Nullable)(BOOL success))block;

/**
 视频压缩

 @param inputURL 输入源路径
 @param outputURL 输出源路径
 @param handler 回调
 */
+ (void)mx_compressQuailtyWithInputURL:(NSURL *)inputURL
                             outputURL:(NSURL *)outputURL
                          blockHandler:(void (^)(AVAssetExportSession * session))handler;

@end

NS_ASSUME_NONNULL_END
