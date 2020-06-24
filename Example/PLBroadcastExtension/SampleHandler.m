//
//  SampleHandler.m
//  PLBroadcastExtension
//
//  Created by 冯文秀 on 2020/6/23.
//  Copyright © 2020 0dayZh. All rights reserved.
//


#import "SampleHandler.h"
#import "BroadcastManager.h"

@interface SampleHandler ()

//@property (nonatomic, strong) BroadcastManager *broadcastManager;

@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension will be supplied.
    #warning 填入您的推流地址
    NSString *streamingURL = @"rtmp://pili-publish.qnsdk.com/sdk-live/Ugc";
    CGSize videoSize = CGSizeMake(540, 960);
    [BroadcastManager createBroadcastManagerWithVideoSize:videoSize streamingURL:streamingURL];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    [[BroadcastManager sharedBroadcastManager] stopStreaming];
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    [[BroadcastManager sharedBroadcastManager] restartStreaming];
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    [[BroadcastManager sharedBroadcastManager] stopStreaming];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    if (sampleBuffer && [BroadcastManager sharedBroadcastManager].streamState == PLStreamStateConnected) {
        @autoreleasepool {
            switch (sampleBufferType) {
                case RPSampleBufferTypeVideo:
                    // Handle video sample buffer
                    [[BroadcastManager sharedBroadcastManager] pushVideoSampleBuffer:sampleBuffer];
                    break;
                case RPSampleBufferTypeAudioApp:
                    // Handle audio sample buffer for app audio
                    [[BroadcastManager sharedBroadcastManager] pushAudioSampleBuffer:sampleBuffer withChannelID:kPLAudioChannelApp];
                    break;
                case RPSampleBufferTypeAudioMic:
                    // Handle audio sample buffer for mic audio
                    [[BroadcastManager sharedBroadcastManager] pushAudioSampleBuffer:sampleBuffer withChannelID:kPLAudioChannelMic];
                    break;
                    
                default:
                    break;
            }
        }
    }
}

@end
