#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// Khai báo biến tĩnh để quản lý luồng đọc video
static AVAssetReader *assetReader = nil;
static AVAssetReaderTrackOutput *assetOutput = nil;

// Hàm bổ trợ để lấy khung hình từ video giả lập
CMSampleBufferRef getFakeBuffer() {
    // Nếu chưa khởi tạo hoặc đã đọc hết video, tiến hành khởi tạo lại (để lặp lại video)
    if (!assetReader || assetReader.status == AVAssetReaderStatusCompleted) {
        // App sẽ tìm file video.mp4 mà bạn đã thêm vào qua ESign
        NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
        if (!videoPath) return NULL;

        NSURL *url = [NSURL fileURLWithPath:videoPath];
        AVAsset *asset = [AVAsset assetWithURL:url];
        AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        if (!track) return NULL;

        NSError *error;
        assetReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
        
        // Thiết lập định dạng màu chuẩn để tránh lỗi màn hình đen (NV12)
        NSDictionary *settings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
        assetOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:settings];
        
        [assetReader addOutput:assetOutput];
        [assetReader startReading];
    }
    return [assetOutput copyNextSampleBuffer];
}

// Đánh chặn (Hook) luồng dữ liệu của Camera
%hook AVCaptureVideoDataOutput

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    // Lấy khung hình từ video giả lập
    CMSampleBufferRef fakeFrame = getFakeBuffer();
    
    if (fakeFrame) {
        // Tráo đổi dữ liệu camera thật bằng khung hình từ video
        %orig(output, fakeFrame, connection);
        CFRelease(fakeFrame);
    } else {
        // Nếu không có video giả, trả về dữ liệu camera thật (để tránh văng app)
        %orig;
    }
}

%end
