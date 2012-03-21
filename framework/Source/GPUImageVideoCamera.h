#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageBase.h"

// From the iOS 5.0 release notes:
// "In previous iOS versions, the front-facing camera would always deliver
// buffers in AVCaptureVideoOrientationLandscapeLeft and the back-facing
// camera would always deliver buffers in AVCaptureVideoOrientationLandscapeRight."
// Currently, rotation is needed to handle each camera

@interface GPUImageVideoCamera : GPUImageBase <AVCaptureVideoDataOutputSampleBufferDelegate, GPUImageFlow>
{
    CVOpenGLESTextureCacheRef coreVideoTextureCache;    
}

@property (readonly) AVCaptureSession *captureSession;

// Initialization and teardown
- (id)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition; 

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

// Manage the camera video stream
- (void)startCameraCapture;
- (void)stopCameraCapture;

@end
