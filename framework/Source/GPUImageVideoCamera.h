#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageBase.h"

@class GPUImageVideoCamera;

@protocol GPUImageVideoCameraDelegate
- (void) videoCameraDidReceiveNewFrame:(GPUImageVideoCamera *)camera;
@end

// From the iOS 5.0 release notes:
// "In previous iOS versions, the front-facing camera would always deliver
// buffers in AVCaptureVideoOrientationLandscapeLeft and the back-facing
// camera would always deliver buffers in AVCaptureVideoOrientationLandscapeRight."
// Currently, rotation is needed to handle each camera

@interface GPUImageVideoCamera : GPUImageBase <AVCaptureVideoDataOutputSampleBufferDelegate, GPUImageSource>
{
    CVOpenGLESTextureCacheRef coreVideoTextureCache;    
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_inputCamera;
}

@property (nonatomic, assign) id <GPUImageVideoCameraDelegate> delegate;
@property (readonly, nonatomic) AVCaptureSession *captureSession;

// Use this property to manage camera settings.Focus point, exposure point, etc.
@property (readonly, nonatomic) AVCaptureDevice *inputCamera;

// Initialization and teardown
- (id) initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition; 

// Manage the camera video stream
- (void) startCameraCapture;
- (void) stopCameraCapture;

// Rotate the camera
- (void) rotateCamera;

@end
