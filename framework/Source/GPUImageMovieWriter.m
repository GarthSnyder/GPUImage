#import "GPUImageMovieWriter.h"
#import "GPUImageOpenGLESContext.h"
#import "GPUImageProgram.h"
#import "GPUImageFilter.h"
#import "GPUImageTextureBuffer.h"

NSString *const kGPUImageColorSwizzlingFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;
    uniform sampler2D inputImage;

    void main()
    {
         gl_FragColor = texture2D(inputImage, textureCoordinate).bgra;
    }
);

@interface GPUImageMovieWriter ()
{
    GPUImageProgram *colorSwizzlingProgram;
    NSDate *startTime;
}

// Movie recording
- (void) initializeMovie;
- (BOOL) render;
- (void) validateSize;
- (void) processNewFrame;
- (void) endProcessing;
@end

@implementation GPUImageMovieWriter

@synthesize inputImage;
@synthesize completionBlock;
@synthesize failureBlock;
@synthesize delegate;

#pragma mark -
#pragma mark Initialization

- (id) initWithMovieURL:(NSURL *)newMovieURL
{
    if (self = [super init]) {
        movieURL = newMovieURL;
        self.baseFormat = GL_RGBA;
        self.wrap = GL_CLAMP_TO_EDGE;
        self.filter = GL_LINEAR;
        colorSwizzlingProgram = [[GPUImageProgram alloc] init];
        if (![GPUImageOpenGLESContext supportsFastTextureUpload]) {
            colorSwizzlingProgram.fragmentShader = kGPUImageColorSwizzlingFragmentShaderString;
        }
    }
    return self;
}

#pragma mark -
#pragma mark Movie recording

- (void) initializeMovie
{
    NSError *error = nil;
    
//    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeAppleM4V error:&error];
    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
        if (failureBlock) {
            failureBlock(error);
        }
        if(self.delegate&&[self.delegate respondsToSelector:@selector(movieWriter:didFailWithError:)]){
            [self.delegate movieWriter:self didFailWithError:error];
        }
    }
    
    NSMutableDictionary * outputSettings = [[NSMutableDictionary alloc] init];
    [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [outputSettings setObject:[NSNumber numberWithInt:self.size.width] forKey:AVVideoWidthKey];
    [outputSettings setObject:[NSNumber numberWithInt:self.size.height] forKey:AVVideoHeightKey];

    /*
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:self.size.width], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:self.size.height], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];

    NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioHorizontalSpacingKey,
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioVerticalSpacingKey,
                                              nil];

    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] init];
    [compressionProperties setObject:videoCleanApertureSettings forKey:AVVideoCleanApertureKey];
    [compressionProperties setObject:videoAspectRatioSettings forKey:AVVideoPixelAspectRatioKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 2000000] forKey:AVVideoAverageBitRateKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 16] forKey:AVVideoMaxKeyFrameIntervalKey];
    [compressionProperties setObject:AVVideoProfileLevelH264Main31 forKey:AVVideoProfileLevelKey];
    
    [outputSettings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
    */
     
    assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    //writerInput.expectsMediaDataInRealTime = NO;
    
    // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                           [NSNumber numberWithInt:self.size.width], kCVPixelBufferWidthKey,
                                                           [NSNumber numberWithInt:self.size.height], kCVPixelBufferHeightKey,
                                                           nil];
//    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
//                                                           nil];
        
    assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [assetWriter addInput:assetWriterVideoInput];
}

- (void) startRecording
{
    if (!assetWriter) {
        [self validateSize];
        [self initializeMovie];
    }
    startTime = [NSDate date];
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
}

- (void) finishRecording
{
    [assetWriterVideoInput markAsFinished];
    [assetWriter finishWriting];
    [self endProcessing];
}

// Make sure we have a defined size before initializing the movie
- (void) validateSize
{
    if (self.size.width && self.size.height) {
        return;
    }
    NSAssert(self.inputImage, @"GPUImageMovieWriter cannot start recording without an explicit size or a parent of known size.");
    NSAssert ([self.inputImage update], @"GPUImageMovieWriter parent could not update when initiating recording.");
    GPUImageBuffer *pBuff = self.inputImage.backingStore;
    self.size = pBuff.size;
}

#pragma mark -
#pragma mark Frame rendering

- (void) createBackingStore
{
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &coreVideoTextureCache);
        NSAssert(!err, @"Error at CVOpenGLESTextureCacheCreate %d");

        // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
        
        CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterPixelBufferInput pixelBufferPool], &renderTarget);

        CVOpenGLESTextureRef renderTexture;
        CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, renderTarget,
                                                      NULL, // texture attributes
                                                      GL_TEXTURE_2D,
                                                      GL_RGBA, // opengl format
                                                      self.size.width,
                                                      self.size.height,
                                                      GL_BGRA, // native iOS format
                                                      GL_UNSIGNED_BYTE,
                                                      0,
                                                      &renderTexture);
        
        _backingStore = [[GPUImageTextureBuffer alloc] initWithTexture:CVOpenGLESTextureGetName(renderTexture) 
                                                                  size:self.size 
                                                                format:self.baseFormat];
        [self setTextureParameters];
    }
    else
    {
        [super createBackingStore];	
    }
}

- (void) setInputImage:(id<GPUImageSource>)newParent
{
    if (inputImage != newParent) {
        inputImage = newParent;
        colorSwizzlingProgram.inputImage = newParent;
        timeLastChanged = 0;
    }
}

- (BOOL) update
{
    if (inputImage) {
        [inputImage update];
        if (timeLastChanged < [inputImage timeLastChanged]) {
            return [self render];
        }
    }
    return YES;
}

- (BOOL) render
{
    if (!self.backingStore) {
        [self createBackingStore];
    }
    [self.backingStore bindAsFramebuffer];
    [self drawWithProgram:colorSwizzlingProgram];
    [self processNewFrame];
    timeLastChanged = GPUImageGetCurrentTimestamp();
    return YES;
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void) processNewFrame
{
    if (!assetWriterVideoInput.readyForMoreMediaData)
    {
//        NSLog(@"Had to drop a frame");
        return;
    }

    CVPixelBufferRef pixel_buffer = NULL;

    if ([GPUImageOpenGLESContext supportsFastTextureUpload]) {
        pixel_buffer = renderTarget; 
        CVPixelBufferLockBaseAddress(pixel_buffer, 0);
    } else {
        CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterPixelBufferInput pixelBufferPool], &pixel_buffer);
        if ((pixel_buffer == NULL) || (status != kCVReturnSuccess)) {
            return;
        } else {
            CVPixelBufferLockBaseAddress(pixel_buffer, 0);
            GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixel_buffer);
            glReadPixels(0, 0, self.size.width, self.size.height, GL_RGBA, GL_UNSIGNED_BYTE, pixelBufferData);
        }
    }
    
    // May need to add a check here, because if two consecutive times with the same value are added to the movie, it aborts recording
    CMTime currentTime = CMTimeMakeWithSeconds([[NSDate date] timeIntervalSinceDate:startTime],120);
    
    if(![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:currentTime]) {
        NSLog(@"Problem appending pixel buffer at time: %lld", currentTime.value);
    } else {
//      NSLog(@"Recorded pixel buffer at time: %lld", currentTime.value);
    }
    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    
    if (![GPUImageOpenGLESContext supportsFastTextureUpload]) {
        CVPixelBufferRelease(pixel_buffer);
    }
}

- (void) endProcessing 
{
    if (completionBlock) {
        completionBlock();
    }
    if(self.delegate&&[delegate respondsToSelector:@selector(movieWriterDidComplete:)]){
        [self.delegate movieWriterDidComplete:self];
    }
}

- (void) dealloc
{
    if (coreVideoTextureCache) {
        CFRelease(coreVideoTextureCache);
    }
}

@end
