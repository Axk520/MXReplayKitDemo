//
//  MXReplayManager.m
//  MXReplayKitDemo
//
//  Created by 66-admin on 2019/11/1.
//  Copyright © 2019 admin. All rights reserved.
//

#import "MXReplayManager.h"

@implementation MXReplayManager

+ (void)mx_getPHAuthorizationStatusBlock:(void (^)(BOOL))block {
    
    BOOL canUsePhoto = YES;
    //相册权限的状态判断需要做版本判断
    PHAuthorizationStatus photoStatus = [PHPhotoLibrary authorizationStatus];
    if (photoStatus == PHAuthorizationStatusRestricted || photoStatus == PHAuthorizationStatusDenied) {
        canUsePhoto = NO;
    } else {
        canUsePhoto = YES;
    }
    if (canUsePhoto) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    if (block) {
                        block(YES);
                    }
                } else {
                    if (block) {
                        block(NO);
                    }
                }
            });
        }];
    } else {
        if (block) {
            block(NO);
        }
    }
}

+ (void)mx_compressQuailtyWithInputURL:(NSURL *)inputURL
                             outputURL:(NSURL *)outputURL
                          blockHandler:(void (^)(AVAssetExportSession * _Nonnull))handler {
    
    AVURLAsset * asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession * session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    session.outputURL = outputURL;
    session.outputFileType = AVFileTypeMPEG4;
    [session exportAsynchronouslyWithCompletionHandler:^(void) {
        if (handler) {
            handler(session);
        }
    }];
}

@end
