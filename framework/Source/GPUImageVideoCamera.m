#import <objc/runtime.h>
#import "GPUImageVideoCamera.h"
#import "GPUImageTexture.h"
#import "GPUImageOpenGLESContext.h"
#import "GPUImage.h"

#pragma mark -
#pragma mark Private methods and instance variables

@interface GPUImageVideoCamera () 
{
	AVCaptureDeviceInput *videoInput;
	AVCaptureVideoDataOutput *videoOutput;
    GPUImageTimestamp timeLastChanged;
}
@end

@implementation GPUImageVideoCamera

@synthesize delegate = _delegate;
@synthesize captureSession = _captureSession;
@synthesize inputCamera = _inputCamera;

#pragma mark -
#pragma mark Initialization and teardown

- (id) init
{
    return [self initWithSessionPreset:AVCaptureSessionPreset640x480 
        cameraPosition:AVCaptureDevicePositionBack];
}

- (id) initWithSessionPreset:(NSString *)sessionPreset 
    cameraPosition:(AVCaptureDevicePosition)cameraPosition; 
{
	if (!(self = [super init])) {
		return nil;
    }
    
    self.baseFormat = GL_RGBA;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    if ([GPUImageOpenGLESContext supportsFastTextureUpload]) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, 
            (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext]
            context], NULL, &coreVideoTextureCache);
        NSAssert(!err, @"Error at CVOpenGLESTextureCacheCreate %d");
    }

    // Grab the back-facing or front-facing camera
    _inputCamera = nil;
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == cameraPosition) {
			_inputCamera = device;
		}
	}
    
	// Create the capture session
	_captureSession = [[AVCaptureSession alloc] init];
	
    [_captureSession beginConfiguration];

	// Add the video input	
	NSError *error = nil;
	videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_inputCamera error:&error];
	if ([_captureSession canAddInput:videoInput]) {
		[_captureSession addInput:videoInput];
	}
	
	// Add the video frame output	
	videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setAlwaysDiscardsLateVideoFrames:YES];

	[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    //	dispatch_queue_t videoQueue = dispatch_queue_create("com.sunsetlakesoftware.colortracking.videoqueue", NULL);
    //	[videoOutput setSampleBufferDelegate:self queue:videoQueue];

	[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
	if ([_captureSession canAddOutput:videoOutput]) {
		[_captureSession addOutput:videoOutput];
	} else {
		NSLog(@"Couldn't add video output");
	}
    
    [_captureSession setSessionPreset:sessionPreset];
    [_captureSession commitConfiguration];

	return self;
}

- (void) dealloc 
{
    [self stopCameraCapture];
//    [videoOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];    
    
    [_captureSession removeInput:videoInput];
    [_captureSession removeOutput:videoOutput];

    if (coreVideoTextureCache) {
        CFRelease(coreVideoTextureCache);
    }
}

#pragma mark -
#pragma mark Manage the camera video stream

- (void) startCameraCapture
{
    if (![_captureSession isRunning])
	{
		[_captureSession startRunning];
	}
}

- (void) stopCameraCapture
{
    if ([_captureSession isRunning])
    {
        [_captureSession stopRunning];
    }
}

- (void) rotateCamera
{
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition currentCameraPosition = [[videoInput device] position];
    
    if(currentCameraPosition == AVCaptureDevicePositionBack)
        currentCameraPosition = AVCaptureDevicePositionFront;
    else
        currentCameraPosition = AVCaptureDevicePositionBack;
    
    AVCaptureDevice *backFacingCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) 
	{
		if ([device position] == currentCameraPosition)
		{
			backFacingCamera = device;
		}
	}
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:&error];
    
    if (newVideoInput != nil)
    {
        [_captureSession beginConfiguration];
        
        [_captureSession removeInput:videoInput];
        if ([_captureSession canAddInput:newVideoInput])
        {
            [_captureSession addInput:newVideoInput];
            videoInput = newVideoInput;
        }
        else
        {
            [_captureSession addInput:videoInput];
        }
        //captureSession.sessionPreset = oriPreset;
        [_captureSession commitConfiguration];
    }
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput 
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
    fromConnection:(AVCaptureConnection *)connection
{
    glPushGroupMarkerEXT(0, [[NSString stringWithFormat:@"Video frame: %s (GPUImageVideoCamera)", 
        class_getName([self class])] UTF8String]);

    CVImageBufferRef imgBuff = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    GLsize buffSize;
    buffSize.width = CVPixelBufferGetWidth(imgBuff);
    buffSize.height = CVPixelBufferGetHeight(imgBuff);
    self.size = buffSize;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    CVPixelBufferLockBaseAddress(imgBuff, 0);
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        CVOpenGLESTextureRef texture = NULL;
        [GPUImageTexture protectTextureContext];
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            coreVideoTextureCache, imgBuff, NULL, GL_TEXTURE_2D, GL_RGBA, 
            buffSize.width, buffSize.height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture);
                
        if (!texture || err) {
            NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);  
            return;
        }
        
        GLint outputTexture = CVOpenGLESTextureGetName(texture);
        if (_canvas.handle != outputTexture) {
            _canvas = [[GPUImageTexture alloc] initWithTexture:outputTexture
                size:buffSize format:GL_RGBA];
        }
        [self setTextureParameters];
        
        // Flush the CVOpenGLESTexture cache and release the texture
        CVOpenGLESTextureCacheFlush(coreVideoTextureCache, 0);
        CFRelease(texture);
    }
    else  
    {
        if (!self.canvas) {
            [self createCanvas];
        }
        [self.canvas bind];
        // Using BGRA extension to pull in video frame data directly
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, buffSize.width, buffSize.height, 0, 
            GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(imgBuff));
    }    
    CVPixelBufferUnlockBaseAddress(imgBuff, 0);
    timeLastChanged = GPUImageGetCurrentTimestamp();

    glPopGroupMarkerEXT();

    if (self.delegate) {
        [self.delegate videoCameraDidReceiveNewFrame:self];
    }
}

#pragma mark -
#pragma mark GPUImageSource methods

// Updates are pushed from the video stream rather than pulled

- (BOOL) update
{
    return YES;
}

- (GPUImageTimestamp) timeLastChanged
{
    return timeLastChanged;
}

- (id<GPUImageSource>) sourceAsRenderbuffer
{
    GPUImage *adapter = [[GPUImage alloc] init];
    adapter.inputImage = self;
    adapter.usesRenderbuffer = YES;
    return adapter;
}

@end
