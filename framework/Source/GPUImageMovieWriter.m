#import "GPUImageMovieWriter.h"

#import "GPUImageOpenGLESContext.h"
#import "GPUImageProgram.h"
#import "GPUImageFilter.h"
#import "GPUImageTextureBuffer.h"

NSString *const kGPUImageColorSwizzlingFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate).bgra;
 }
);

@interface GPUImageMovieWriter ()
{
    GLuint movieFramebuffer, movieRenderbuffer;
    
    GPUImageProgram *colorSwizzlingProgram;
    GLint colorSwizzlingPositionAttribute, colorSwizzlingTextureCoordinateAttribute;
    GLint colorSwizzlingInputTextureUniform;

    GLuint inputTextureForMovieRendering;
    
    GLubyte *frameData;
    
    CMTime startTime, previousFrameTime;
    
    BOOL isRecording;
}

// Movie recording
- (void)initializeMovie;

// Frame rendering
- (void)createDataFBO;
- (void)destroyDataFBO;
- (void)setFilterFBO;

- (void)renderAtInternalSize;

@end

@implementation GPUImageMovieWriter

@synthesize hasAudioTrack = _hasAudioTrack;
@synthesize encodingLiveVideo = _encodingLiveVideo;
@synthesize shouldPassthroughAudio = _shouldPassthroughAudio;
@synthesize completionBlock;
@synthesize failureBlock;
@synthesize videoInputReadyCallback;
@synthesize audioInputReadyCallback;

@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    videoSize = newSize;
    movieURL = newMovieURL;
    startTime = kCMTimeInvalid;
    _encodingLiveVideo = YES;
    previousFrameTime = kCMTimeNegativeInfinity;
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    
    colorSwizzlingProgram = [[GPUImageProgram alloc] initWithVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
    
    [colorSwizzlingProgram addAttribute:@"position"];
	[colorSwizzlingProgram addAttribute:@"inputTextureCoordinate"];
    
    if (![colorSwizzlingProgram link])
	{
		NSString *progLog = [colorSwizzlingProgram programLog];
		NSLog(@"Program link log: %@", progLog); 
		NSString *fragLog = [colorSwizzlingProgram fragmentShaderLog];
		NSLog(@"Fragment shader compile log: %@", fragLog);
		NSString *vertLog = [colorSwizzlingProgram vertexShaderLog];
		NSLog(@"Vertex shader compile log: %@", vertLog);
		colorSwizzlingProgram = nil;
        NSAssert(NO, @"Filter shader link failed");
	}
    
    colorSwizzlingPositionAttribute = [colorSwizzlingProgram attributeIndex:@"position"];
    colorSwizzlingTextureCoordinateAttribute = [colorSwizzlingProgram attributeIndex:@"inputTextureCoordinate"];
    colorSwizzlingInputTextureUniform = [colorSwizzlingProgram uniformIndex:@"inputImageTexture"];
    
    [colorSwizzlingProgram use];    
	glEnableVertexAttribArray(colorSwizzlingPositionAttribute);
	glEnableVertexAttribArray(colorSwizzlingTextureCoordinateAttribute);
    
    [self initializeMovie];

    return self;
}

- (void)dealloc;
{
    [self destroyDataFBO];

    if (frameData != NULL)
    {
        free(frameData);
    }
}

#pragma mark -
#pragma mark Movie recording

- (void) initializeMovie
{
    isRecording = NO;
    
    frameData = (GLubyte *) malloc((int)videoSize.width * (int)videoSize.height * 4);

//    frameData = (GLubyte *) calloc(videoSize.width * videoSize.height * 4, sizeof(GLubyte));
    NSError *error = nil;
    assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
        if (failureBlock) 
        {
            failureBlock(error);
        }
        else 
        {
            if(self.delegate && [self.delegate respondsToSelector:@selector(movieRecordingFailedWithError:)])
            {
                [self.delegate movieRecordingFailedWithError:error];
            }
        }
    }
    
    // Set this to make sure that a functional movie is produced, even if the recording is cut off mid-stream. Only the last second should be lost in that case.
    assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000);
    
    NSMutableDictionary * outputSettings = [[NSMutableDictionary alloc] init];
    [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [outputSettings setObject:[NSNumber numberWithInt:videoSize.width] forKey:AVVideoWidthKey];
    [outputSettings setObject:[NSNumber numberWithInt:videoSize.height] forKey:AVVideoHeightKey];

    /*
    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:videoSize.width], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:videoSize.height], AVVideoCleanApertureHeightKey,
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
    assetWriterVideoInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    
    // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                           [NSNumber numberWithInt:videoSize.width], kCVPixelBufferWidthKey,
                                                           [NSNumber numberWithInt:videoSize.height], kCVPixelBufferHeightKey,
                                                           nil];
//    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
//                                                           nil];
        
    assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    [assetWriter addInput:assetWriterVideoInput];
}

- (void) startRecording
{
    isRecording = YES;
    startTime = kCMTimeInvalid;
//    [assetWriter startWriting];
    
//    [assetWriter startSessionAtSourceTime:kCMTimeZero];
}

- (void) finishRecording
{
    isRecording = NO;
//    [assetWriterVideoInput markAsFinished];
    [assetWriter finishWriting];    
}

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;
{
    if (!isRecording)
    {
        return;
    }
    
    if (_hasAudioTrack)
    {
        CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(audioBuffer);
        
        if (CMTIME_IS_INVALID(startTime))
        {
            if (audioInputReadyCallback == NULL)
            {
                [assetWriter startWriting];
            }
            [assetWriter startSessionAtSourceTime:currentSampleTime];
            startTime = currentSampleTime;
        }

        if (!assetWriterAudioInput.readyForMoreMediaData)
        {
            NSLog(@"Had to drop an audio frame");
            return;
        }
        
//        NSLog(@"Recorded audio sample time: %lld, %d, %lld", currentSampleTime.value, currentSampleTime.timescale, currentSampleTime.epoch);
        [assetWriterAudioInput appendSampleBuffer:audioBuffer];
    }
}

- (void)enableSynchronizationCallbacks;
{
    if (videoInputReadyCallback != NULL)
    {
        [assetWriter startWriting];
        [assetWriterVideoInput requestMediaDataWhenReadyOnQueue:dispatch_get_main_queue() usingBlock:videoInputReadyCallback];
    }
    
    if (audioInputReadyCallback != NULL)
    {
        [assetWriterAudioInput requestMediaDataWhenReadyOnQueue:dispatch_get_main_queue() usingBlock:audioInputReadyCallback];
    }        
    
}

#pragma mark -
#pragma mark Frame rendering

- (void) createCanvas
{
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &movieFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &coreVideoTextureCache);
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d");
    }

    // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
    

    CVPixelBufferPoolCreatePixelBuffer (NULL, [assetWriterPixelBufferInput pixelBufferPool], &renderTarget);

    CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, renderTarget,
                                                  NULL, // texture attributes
                                                  GL_TEXTURE_2D,
                                                  GL_RGBA, // opengl format
                                                  (int)videoSize.width,
                                                  (int)videoSize.height,
                                                  GL_BGRA, // native iOS format
                                                  GL_UNSIGNED_BYTE,
                                                  0,
                                                  &renderTexture);
    
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)destroyDataFBO;
{
    if (movieFramebuffer)
	{
		glDeleteFramebuffers(1, &movieFramebuffer);
		movieFramebuffer = 0;
	}	
    
    if (movieRenderbuffer)
	{
		glDeleteRenderbuffers(1, &movieRenderbuffer);
		movieRenderbuffer = 0;
	}	
    
    if (coreVideoTextureCache)
    {
        CFRelease(coreVideoTextureCache);
    }

    if (renderTexture)
    {
        CFRelease(renderTexture);
    }
    if (renderTarget)
    {
        CVPixelBufferRelease(renderTarget);
    }
}

- (void)setFilterFBO;
{
    if (!movieFramebuffer)
    {
        [self createDataFBO];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    glViewport(0, 0, (int)videoSize.width, (int)videoSize.height);
}

- (void)renderAtInternalSize;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self setFilterFBO];
    
    [colorSwizzlingProgram use];
    
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // This needs to be flipped to write out to video correctly
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
	glActiveTexture(GL_TEXTURE4);
	glBindTexture(GL_TEXTURE_2D, inputTextureForMovieRendering);
	glUniform1i(colorSwizzlingInputTextureUniform, 4);	
    
    glVertexAttribPointer(colorSwizzlingPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
	glVertexAttribPointer(colorSwizzlingTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFlush();
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime;
{
    if (!isRecording)
    {
        return;
    }

    // Drop frames forced by images and other things with no time constants
    // Also, if two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case
    if ( (CMTIME_IS_INVALID(frameTime)) || (CMTIME_COMPARE_INLINE(frameTime, ==, previousFrameTime)) ) 
    {
        return;
    }

    if (CMTIME_IS_INVALID(startTime))
    {
        if (videoInputReadyCallback == NULL)
        {
            [assetWriter startWriting];
        }
        
        [assetWriter startSessionAtSourceTime:frameTime];
        startTime = frameTime;
    }

    if (!assetWriterVideoInput.readyForMoreMediaData)
    {
        NSLog(@"Had to drop a video frame");
        return;
    }
    
    // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
    [GPUImageOpenGLESContext useImageProcessingContext];
    [self renderAtInternalSize];

    CVPixelBufferRef pixel_buffer = NULL;

    pixel_buffer = renderTarget; 
    CVPixelBufferLockBaseAddress(pixel_buffer, 0);
    
//    if(![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:CMTimeSubtract(frameTime, startTime)]) 
    if(![assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:frameTime]) 
    {
        NSLog(@"Problem appending pixel buffer at time: %lld", frameTime.value);
    } 
    else 
    {
//        NSLog(@"Recorded video sample time: %lld, %d, %lld", frameTime.value, frameTime.timescale, frameTime.epoch);
    }
    CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    
    previousFrameTime = frameTime;
    
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputTexture:(GLuint)newInputTexture atIndex:(NSInteger)textureIndex;
{
    inputTextureForMovieRendering = newInputTexture;
}

- (void)setInputSize:(CGSize)newSize;
{
}

- (CGSize)maximumOutputSize;
{
    return videoSize;
}

- (void)endProcessing 
{
    if (completionBlock) 
    {
        completionBlock();
    }
    else 
    {
        if (_delegate && [_delegate respondsToSelector:@selector(movieRecordingCompleted)])
        {
            [_delegate movieRecordingCompleted];
        }
    }
}

- (BOOL)shouldIgnoreUpdatesToThisTarget;
{
    return NO;
}

#pragma mark -
#pragma mark Accessors

- (void)setHasAudioTrack:(BOOL)newValue
{
    _hasAudioTrack = newValue;
    
    if (_hasAudioTrack)
    {
        NSDictionary *audioOutputSettings = nil;
        if (_shouldPassthroughAudio)
        {
//            float ver = [[[UIDevice currentDevice] systemVersion] floatValue];
//            if (ver < 4.3) // Older iOS versions complain about using nil settings for passthrough audio, so I need to check for that
//            {
//                double preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
//                
//                AudioChannelLayout acl;
//                bzero( &acl, sizeof(acl));
//                acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
//                
//                audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                       [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
//                                       [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
//                                       [ NSNumber numberWithFloat: preferredHardwareSampleRate ], AVSampleRateKey,
//                                       [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
//                                       //[ NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
//                                       [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
//                                       nil];
//            }
//            else
//            {
                audioOutputSettings = nil;                
//            }
        }
        else
        {
            double preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
            
            AudioChannelLayout acl;
            bzero( &acl, sizeof(acl));
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            
            audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                         [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                         [ NSNumber numberWithFloat: preferredHardwareSampleRate ], AVSampleRateKey,
                                         [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                         //[ NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
                                         [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                         nil];
/*
            AudioChannelLayout acl;
            bzero( &acl, sizeof(acl));
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            
            audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                                   [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                   [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                                   [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                   [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                   nil];*/
        }
        
        assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
        [assetWriter addInput:assetWriterAudioInput];
        assetWriterAudioInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    }
    else
    {
        // Remove audio track if it exists
    }
}


@end
