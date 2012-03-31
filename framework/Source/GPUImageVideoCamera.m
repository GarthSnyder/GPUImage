#import "GPUImageVideoCamera.h"
#import "GPUImageTexture.h"
#import "GPUImageOpenGLESContext.h"
#import "GPUImage.h"
#import <objc/runtime.h>

#pragma mark -
#pragma mark Private methods and instance variables

@interface GPUImageVideoCamera () 
{
	AVCaptureDeviceInput *videoInput;
	AVCaptureDeviceInput *audioInput;
	AVCaptureVideoDataOutput *videoOutput;
    GPUImageTimestamp timeLastChanged;
	AVCaptureAudioDataOutput *audioOutput;
    NSDate *startingCaptureTime;
    
    dispatch_queue_t audioProcessingQueue;
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

   
	if ([_captureSession canAddOutput:videoOutput]) {
    
	//[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
	//this should be on the same queue as the audio
    [videoOutput setSampleBufferDelegate:self queue:audioProcessingQueue];
	if ([_captureSession canAddOutput:videoOutput])
	{
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
    
    [self removeInputsAndOutputs];
    
    if (coreVideoTextureCache) {
        CFRelease(coreVideoTextureCache);
    }
    
    if (audioProcessingQueue != NULL)
    {
        dispatch_release(audioProcessingQueue);
    }
}

- (void)removeInputsAndOutputs;
{
    [_captureSession removeInput:videoInput];
    [_captureSession removeOutput:videoOutput];
    if (_microphone != nil)
    {
        [_captureSession removeInput:audioInput];
        [_captureSession removeOutput:audioOutput];
    }
}

#pragma mark -
#pragma mark Manage the camera video stream

- (void) startCameraCapture
{
    if (![_captureSession isRunning])
	{
        startingCaptureTime = [NSDate date];
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
    {
        currentCameraPosition = AVCaptureDevicePositionFront;
    }
    else
    {
        currentCameraPosition = AVCaptureDevicePositionBack;
    }
    
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
            NSLog(@"Camera CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
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

- (void)processAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    [self.audioEncodingTarget processAudioBuffer:sampleBuffer]; 
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	//This may help keep memory footprint low
	@autoreleasepool 
	{
		//these need to be on the main thread for proper timing
		if (captureOutput == audioOutput)
		{
			runOnMainQueueWithoutDeadlocking(^{ 
                [self processAudioSampleBuffer:sampleBuffer]; 
            });
		}
		else
		{
			runOnMainQueueWithoutDeadlocking(^{ 
                [self processVideoSampleBuffer:sampleBuffer]; 
            });
		}
	}
}

#pragma mark -
#pragma mark Accessors

- (void)setAudioEncodingTarget:(GPUImageMovieWriter *)newValue;
{    
    [_captureSession beginConfiguration];

    if (newValue == nil)
    {
        if (audioOutput)
        {
            [_captureSession removeInput:audioInput];
            [_captureSession removeOutput:audioOutput];
            audioInput = nil;
            audioOutput = nil;
            _microphone = nil;
            dispatch_release(audioProcessingQueue);
            audioProcessingQueue = NULL;
        }        
    }
    else
    {        
        _microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        audioInput = [AVCaptureDeviceInput deviceInputWithDevice:_microphone error:nil];
        if ([_captureSession canAddInput:audioInput]) 
        {
            [_captureSession addInput:audioInput];
        }
        audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        
        audioProcessingQueue = dispatch_queue_create("com.sunsetlakesoftware.GPUImage.audioProcessingQueue", NULL);
        
        //    [audioOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
        if ([_captureSession canAddOutput:audioOutput])
        {
            [_captureSession addOutput:audioOutput];
        }
        else
        {
            NSLog(@"Couldn't add audio output");
        }
        [audioOutput setSampleBufferDelegate:self queue:audioProcessingQueue];        
    }
    
    [_captureSession commitConfiguration];
    
    [super setAudioEncodingTarget:newValue];
}

- (id<GPUImageSource>) sourceAsRenderbuffer
{
    GPUImage *adapter = [[GPUImage alloc] init];
    adapter.inputImage = self;
    adapter.usesRenderbuffer = YES;
    return adapter;
}

@end
