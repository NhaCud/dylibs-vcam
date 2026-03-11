#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

static AVAssetReader *assetReader = nil;
static AVAssetReaderTrackOutput *assetOutput = nil;

CMSampleBufferRef getFakeBuffer() {
    if (!assetReader || assetReader.status == AVAssetReaderStatusCompleted) {
        NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
        if (!videoPath) return NULL;

        NSURL *url = [NSURL fileURLWithPath:videoPath];
        AVAsset *asset = [AVAsset assetWithURL:url];
        AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        if (!track) return NULL;

        NSError *error;
        assetReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
        assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track 
                                                            outputSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)}];
        [assetReader addOutput:assetOutput];
        [assetReader startReading];
    }
    return [assetOutput copyNextSampleBuffer];
}

%hook AVCaptureVideoDataOutput
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CMSampleBufferRef fakeFrame = getFakeBuffer();
    if (fakeFrame) {
        %orig(output, fakeFrame, connection);
        CFRelease(fakeFrame);
    } else {
        %orig;
    }
}
%end
