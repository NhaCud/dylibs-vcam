#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>

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
``` [[3]](grok://citation?card_id=f2ff97&card_type=citation_card&type=render_inline_citation&citation_id=3)

### Cách áp dụng
- Vào GitHub > repo > edit từng file > paste code trên > Commit (mô tả "Fix linker errors and imports").
- Push hoặc merge PR để trigger build mới.
- Check tab Actions > build mới > nếu success, download artifact "dylib" (.deb).

Nếu vẫn fail (ví dụ do SDK version hoặc rootless), thêm vào Makefile: `FakeCamera_ARCHS = arm64 arm64e` và uncomment rootless nếu cần. Paste log mới nếu error.