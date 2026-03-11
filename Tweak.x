#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>  // Fix cho kCVPixelBufferPixelFormatTypeKey

%hook AVAssetReader

- (AVAssetReaderTrackOutput *)addTrackOutputWithTrack:(AVAssetTrack *)track outputSettings:(NSDictionary *)outputSettings {
    NSLog(@"[FakeCamera] Intercepted AVAssetReader addTrackOutputWithTrack");

    NSMutableDictionary *newSettings = [outputSettings mutableCopy];
    if (newSettings) {
        newSettings[(id)kCVPixelBufferPixelFormatTypeKey] = @(kCVPixelFormatType_32BGRA);
    }

    return %orig(track, newSettings);
}

- (BOOL)startReading {
    NSLog(@"[FakeCamera] AVAssetReader startReading – Fake camera activated!");
    return %orig;
}

%end

%hook AVCaptureDevice

+ (NSArray *)devices {
    NSLog(@"[FakeCamera] Fake devices list");
    return %orig;
}

%end

%ctor {
    NSLog(@"[FakeCamera] Tweak loaded successfully!");
}