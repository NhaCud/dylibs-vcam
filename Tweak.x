#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

// Hook vào class xử lý video, ví dụ AVCaptureSession hoặc AVAssetReader (tùy app target)
// Giả sử hook vào AVAssetReader để manipulate frame (fake camera)

%hook AVAssetReader

- (AVAssetReaderTrackOutput *)addTrackOutputWithTrack:(AVAssetTrack *)track outputSettings:(NSDictionary *)outputSettings {
    NSLog(@"[FakeCamera] Intercepted AVAssetReader addTrackOutputWithTrack");

    // Ví dụ: Thay đổi outputSettings để fake frame (grayscale, rotate, etc.)
    NSMutableDictionary *newSettings = [outputSettings mutableCopy];
    if (newSettings) {
        // Sample manipulation: force pixel format to BGRA (hoặc custom)
        newSettings[(id)kCVPixelBufferPixelFormatTypeKey] = @(kCVPixelFormatType_32BGRA);
    }

    AVAssetReaderTrackOutput *output = %orig(track, newSettings);
    return output;
}

- (BOOL)startReading {
    NSLog(@"[FakeCamera] AVAssetReader startReading – Fake camera activated!");
    BOOL result = %orig;
    // Thêm logic fake frame ở đây nếu cần (ví dụ inject UIImage)
    return result;
}

%end

// Hook thêm nếu cần vào AVCaptureDevice hoặc app-specific class
%hook AVCaptureDevice

+ (NSArray *)devices {
    NSLog(@"[FakeCamera] Fake devices list");
    return %orig;  // Hoặc return custom array nếu muốn fake camera device
}

%end

%ctor {
    NSLog(@"[FakeCamera] Tweak loaded successfully!");
}