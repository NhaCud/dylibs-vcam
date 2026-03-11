#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <libactivator/libactivator.h>

// ==================== CONSTANTS ====================
#define DEFAULT_IP @"192.168.1.100"
#define DEFAULT_PORT 8080
#define PLIST_PATH @"/var/mobile/Library/Preferences/com.nhacud.vcam.plist"

// ==================== NETWORK MANAGER ====================
@interface VCAMNetworkManager : NSObject
@property (nonatomic, assign) int clientSocket;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, strong) NSString *serverIP;
@property (nonatomic, assign) int serverPort;
+ (instancetype)sharedInstance;
- (BOOL)connect;
- (void)disconnect;
- (void)sendData:(NSData *)data;
@end

@implementation VCAMNetworkManager

+ (instancetype)sharedInstance {
    static VCAMNetworkManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VCAMNetworkManager alloc] init];
        instance.clientSocket = -1;
        instance.isConnected = NO;
        
        // Đọc cấu hình từ file preferences
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH];
        instance.serverIP = prefs[@"serverIP"] ?: DEFAULT_IP;
        instance.serverPort = [prefs[@"serverPort"] intValue] ?: DEFAULT_PORT;
    });
    return instance;
}

- (BOOL)connect {
    if (self.isConnected) return YES;
    
    self.clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (self.clientSocket < 0) {
        NSLog(@"VCAM: Không thể tạo socket");
        return NO;
    }
    
    struct sockaddr_in serverAddr;
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(self.serverPort);
    serverAddr.sin_addr.s_addr = inet_addr([self.serverIP UTF8String]);
    
    int result = connect(self.clientSocket, (struct sockaddr *)&serverAddr, sizeof(serverAddr));
    self.isConnected = (result >= 0);
    
    if (self.isConnected) {
        NSLog(@"VCAM: Kết nối thành công đến %@:%d", self.serverIP, self.serverPort);
    } else {
        NSLog(@"VCAM: Kết nối thất bại");
        close(self.clientSocket);
        self.clientSocket = -1;
    }
    
    return self.isConnected;
}

- (void)disconnect {
    if (self.clientSocket >= 0) {
        close(self.clientSocket);
        self.clientSocket = -1;
    }
    self.isConnected = NO;
    NSLog(@"VCAM: Đã ngắt kết nối");
}

- (void)sendData:(NSData *)data {
    if (self.isConnected && self.clientSocket >= 0 && data.length > 0) {
        send(self.clientSocket, [data bytes], [data length], 0);
    }
}
@end

// ==================== ACTIVATOR LISTENER ====================
@interface VCAMListener : NSObject <LAListener>
@property (nonatomic, assign) BOOL isEnabled;
@end

@implementation VCAMListener

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    self.isEnabled = !self.isEnabled;
    
    if (self.isEnabled) {
        // Bật webcam
        BOOL connected = [[VCAMNetworkManager sharedInstance] connect];
        if (connected) {
            // Thông báo bằng rung
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            // Hiện thông báo (tùy chọn)
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"VCAM" 
                                                                           message:@"Đã bật chế độ webcam" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            
            // Tự ẩn sau 1 giây
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:nil];
            });
        }
    } else {
        // Tắt webcam
        [[VCAMNetworkManager sharedInstance] disconnect];
        
        // Thông báo bằng rung 2 lần
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    
    [event setHandled:YES];
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
    // Xử lý khi bị hủy (nếu cần)
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"VCAM Webcam";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    return @"Bật/Tắt VCAM Webcam";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    return @"Biến iPhone thành webcam không dây";
}

@end

// ==================== CAMERA HOOK ====================
%hook AVCaptureVideoDataOutput

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    %orig;
    
    // Kiểm tra xem webcam có đang bật không
    VCAMListener *listener = (VCAMListener *)[[LAActivator sharedInstance] listenerForName:@"com.nhacud.vcam"];
    if (!listener.isEnabled) return;
    
    // Kiểm tra kết nối
    VCAMNetworkManager *network = [VCAMNetworkManager sharedInstance];
    if (!network.isConnected) return;
    
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
        
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        size_t stride = CVPixelBufferGetBytesPerRow(imageBuffer);
        void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
        
        // Giảm kích thước để gửi nhanh hơn (nếu cần)
        // Ở đây tạm thời gửi raw data
        NSData *imageData = [NSData dataWithBytes:baseAddress length:stride * height];
        
        // Gửi qua mạng
        [network sendData:imageData];
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    }
}

%end

// ==================== INITIALIZATION ====================
%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // Đăng ký listener với Activator
    static VCAMListener *listener = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        listener = [[VCAMListener alloc] init];
        [[LAActivator sharedInstance] registerListener:listener forName:@"com.nhacud.vcam"];
        NSLog(@"VCAM: Đã đăng ký Activator listener");
    });
    
    return result;
}

%end