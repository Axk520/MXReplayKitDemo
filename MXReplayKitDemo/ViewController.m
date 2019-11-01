//
//  ViewController.m
//  MXReplayKitDemo
//
//  Created by 66-admin on 2019/11/1.
//  Copyright © 2019 admin. All rights reserved.
//

#import "ViewController.h"
#import "MXReplayManager.h"
#import <ReplayKit/ReplayKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
{
    RPScreenRecorder * _recorder;
}

@property (nonatomic, strong) AVPlayer     * player;
@property (nonatomic, strong) AVPlayerItem * currentPlayerItem;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSURL * URL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ReplayKit_Demo" ofType:@"mp4"]];
    AVPlayerItem * playerItem = [[AVPlayerItem alloc] initWithURL:URL];
    self.currentPlayerItem = playerItem;
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];

    AVPlayerLayer * avLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    avLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    avLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * 9.f / 16.f);
    [self.view.layer addSublayer:avLayer];
    
    [self.player play];
    
    UIButton * startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [startButton setFrame:CGRectMake(100, self.view.frame.size.width * 9.f / 16.f + 50, 100, 50)];
    [startButton setBackgroundColor:[UIColor greenColor]];
    [startButton addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchUpInside];
    [startButton setTitle:@"开始录屏" forState:UIControlStateNormal];
    [self.view addSubview:startButton];
    
    UIButton * stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopButton setFrame:CGRectMake(CGRectGetMaxX(startButton.frame) + 50, startButton.frame.origin.y, startButton.frame.size.width, startButton.frame.size.height)];
    [stopButton setBackgroundColor:[UIColor redColor]];
    [stopButton addTarget:self action:@selector(stopRecord) forControlEvents:UIControlEventTouchUpInside];
    [stopButton setTitle:@"停止录屏" forState:UIControlStateNormal];
    [self.view addSubview:stopButton];
    
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(startButton.frame.origin.x, CGRectGetMaxY(startButton.frame) + 50, 100, 100)];
    view.backgroundColor = [UIColor orangeColor];
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragView:)];
    [view addGestureRecognizer:pan];
    [self.view addSubview:view];
    
    _recorder = [RPScreenRecorder sharedRecorder];
}

- (void)startRecord {
    
    [MXReplayManager mx_getPHAuthorizationStatusBlock:^(BOOL success) {
        if (success) {
            [self mx_recorderAvailable];
        }
    }];
}

// 录屏是否可用
- (void)mx_recorderAvailable {
    
    if ([_recorder isAvailable]) {
        [self mx_startCapture];
    } else {
        NSLog(@"请允许App录制屏幕且使用麦克风(选择第一项)，否则无法进行录屏");
    }
}

// 开始录制
- (void)mx_startCapture {
    
    //是否录麦克风的声音（如果只想要App内的声音，设置为NO即可）
    _recorder.microphoneEnabled = NO;

    if ([_recorder isRecording]) {
        NSLog(@"正在录制...");
    } else {
        if (@available(iOS 11.0, *)) {
            [_recorder startCaptureWithHandler:^(CMSampleBufferRef _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
                //CMSampleBufferRef 视频+音频原始帧数据 (帧数据处理可参考部分开源直播SDk)
                switch (bufferType) {
                    case RPSampleBufferTypeVideo:     //视频
                        break;
                     case RPSampleBufferTypeAudioApp: //App内音频
                        break;
                    case RPSampleBufferTypeAudioMic:  //麦克风音频
                        break;
                    default:
                        break;
                }
            } completionHandler:^(NSError * _Nullable error) {
                
            }];
        } else if (@available(iOS 10.0, *)) {
            [_recorder startRecordingWithHandler:^(NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"启动录屏成功...");
                }
            }];
        } else if (@available(iOS 9.0, *)) {
            [_recorder startRecordingWithMicrophoneEnabled:NO handler:^(NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"启动录屏成功...");
                }
            }];
        }
    }
}

//停止录屏
- (void)stopRecord {
 
    if (@available(iOS 11.0, *)) {
        [_recorder stopCaptureWithHandler:^(NSError * _Nullable error) {
            
        }];
    } else {
        [_recorder stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            NSURL * videoURL = [previewViewController valueForKey:@"movieURL"];
            if (!videoURL) {
                NSLog(@"录屏失败...");
            } else {
                //是否需要展示预览界面给用户，自行决定
                [self mx_saveVideoToPhoto:videoURL];
            }
        }];
    }
}

//保存视频至相册
- (void)mx_saveVideoToPhoto:(NSURL *)videoURL {
    
    NSString * videoPath = [videoURL path];
    BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath);
    if (compatible) {
        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
    }
}

//保存视频完成之后的回调
- (void)savedPhotoImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    if (error) {
        NSLog(@"保存视频失败 == %@", error.description);
    } else {
        //取出这个视频并按创建日期排序
        PHFetchOptions * options = [[PHFetchOptions alloc] init];
        options.sortDescriptors  = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        PHFetchResult * assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
        PHAsset * phasset = [assetsFetchResults lastObject];
        if (phasset) {
            //视频文件
            if (phasset.mediaType == PHAssetMediaTypeVideo) {
                PHImageManager * manager = [PHImageManager defaultManager];
                [manager requestAVAssetForVideo:phasset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    AVURLAsset * urlAsset = (AVURLAsset *)asset;
                    [self mx_saveVideoToDocument:urlAsset.URL];
                }];
            } else {
                NSLog(@"未成功保存视频...");
            }
        } else {
            NSLog(@"未成功保存视频...");
        }
    }
}

//压缩完保存视频到沙盒
- (void)mx_saveVideoToDocument:(NSURL *)videoURL {
    
    NSString * outPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[@"mx_test_replay" stringByAppendingString:@".mp4"]];
    [MXReplayManager mx_compressQuailtyWithInputURL:videoURL outputURL:[NSURL fileURLWithPath:outPath] blockHandler:^(AVAssetExportSession * _Nonnull session) {
        if (session.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"视频已处理好可以对其进行操作");
            //处理完的视频是否需要删除？自行决定
        } else {
            NSLog(@"视频压缩出错...");
        }
    }];
}

- (void)dragView:(UIPanGestureRecognizer *)pan {
    
    CGPoint point = [pan translationInView:self.view];
    pan.view.center = CGPointMake(pan.view.center.x + point.x, pan.view.center.y + point.y);
    [pan setTranslation:CGPointMake(0, 0) inView:self.view];
}

@end
