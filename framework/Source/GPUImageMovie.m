#import "GPUImageMovie.h"
#import "GPUImageMovieWriter.h"

@interface GPUImageMovie ()
{
    BOOL audioEncodingIsFinished, videoEncodingIsFinished;
    GPUImageMovieWriter *synchronizedMovieWriter;
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    AVAssetReader *reader;
}

@end

@interface GPUImageMovie ()
{
    GPUImageTimestamp timeLastChanged;
}
@end

@implementation GPUImageMovie

@synthesize url = _url;
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithURL:(NSURL *)url;
{
    if (!(self = [super init])) 
    {
        return nil;
    }
    
    if ([GPUImageOpenGLESContext supportsFastTextureUpload])
    {
        [GPUImageOpenGLESContext useImageProcessingContext];
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] context], NULL, &coreVideoTextureCache);
        if (err) 
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d");
        }
        
        // Need to remove the initially created texture
        [self deleteOutputTexture];
    }

    self.url = url;
    
    return self;
}

#pragma mark -
#pragma mark Movie processing

- (void)enableSynchronizedEncodingUsingMovieWriter:(GPUImageMovieWriter *)movieWriter;
{
    synchronizedMovieWriter = movieWriter;
    movieWriter.encodingLiveVideo = NO;
}

- (void)startProcessing;
{
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:self.url options:inputOptions];
    
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
        if (!tracksStatus == AVKeyValueStatusLoaded) 
        {
            return;
        }
        reader = [AVAssetReader assetReaderWithAsset:inputAsset error:&error];
        
        NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
        [outputSettings setObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]  forKey: (NSString*)kCVPixelBufferPixelFormatTypeKey];
        // Maybe set alwaysCopiesSampleData to NO on iOS 5.0 for faster video decoding
        AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
        [reader addOutput:readerVideoTrackOutput];
        
        NSArray *audioTracks = [inputAsset tracksWithMediaType:AVMediaTypeAudio];
        BOOL shouldRecordAudioTrack = (([audioTracks count] > 0) && (self.audioEncodingTarget != nil) );
        AVAssetReaderTrackOutput *readerAudioTrackOutput = nil;

        if (shouldRecordAudioTrack)
        {            
            audioEncodingIsFinished = NO;
            
            // This might need to be extended to handle movies with more than one audio track
            AVAssetTrack* audioTrack = [audioTracks objectAtIndex:0];
            readerAudioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
            [reader addOutput:readerAudioTrackOutput];
        }

        if ([reader startReading] == NO) 
        {
            NSLog(@"Error reading from file at URL: %@", self.url);
            return;
        }
        
        if (synchronizedMovieWriter != nil)
        {
            __unsafe_unretained GPUImageMovie *weakSelf = self;
            
            [synchronizedMovieWriter setVideoInputReadyCallback:^{
                [weakSelf readNextVideoFrameFromOutput:readerVideoTrackOutput];
            }];

            [synchronizedMovieWriter setAudioInputReadyCallback:^{
                [weakSelf readNextAudioSampleFromOutput:readerAudioTrackOutput];
            }];
            
            [synchronizedMovieWriter enableSynchronizationCallbacks];
        }
        else
        {
            while (reader.status == AVAssetReaderStatusReading) 
            {
                [self readNextVideoFrameFromOutput:readerVideoTrackOutput];
                
                if ( (shouldRecordAudioTrack) && (!audioEncodingIsFinished) )
                {
                    [self readNextAudioSampleFromOutput:readerAudioTrackOutput];
                }
                
            }            

            if (reader.status == AVAssetWriterStatusCompleted) {
                [self endProcessing];
            }
        }
    }];
}

- (void)readNextVideoFrameFromOutput:(AVAssetReaderTrackOutput *)readerVideoTrackOutput;
{
    if (reader.status == AVAssetReaderStatusReading)
    {
        CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
        if (sampleBufferRef) 
        {
            runOnMainQueueWithoutDeadlocking(^{
                [self processMovieFrame:sampleBufferRef]; 
            });
            
            CMSampleBufferInvalidate(sampleBufferRef);
            CFRelease(sampleBufferRef);
        }
        else
        {
            videoEncodingIsFinished = YES;
            [self endProcessing];
        }
    }
    else if (synchronizedMovieWriter != nil)
    {
        if (reader.status == AVAssetWriterStatusCompleted) 
        {
            [self endProcessing];
        }
    }];
}

- (void)processFrame 
{
    // Upload to texture
    CVPixelBufferLockBaseAddress(_currentBuffer, 0);
    GLsize buffSize;
    buffSize.height = CVPixelBufferGetHeight(_currentBuffer);
    buffSize.width = CVPixelBufferGetWidth(_currentBuffer);
    
    [GPUImageOpenGLESContext useImageProcessingContext];

    self.usesRenderbuffer = NO;
    self.size = buffSize;
    self.pixType = GL_UNSIGNED_BYTE;
    self.baseFormat = GL_RGBA;
    
    if (!self.backingStore) {
        [self createBackingStore];
    } else {
        [self.backingStore bind];
    }

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, buffSize.width, buffSize.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(_currentBuffer));
    CVPixelBufferUnlockBaseAddress(_currentBuffer, 0);

    if (self.generatesMipmap) {
        [self.backingStore generateMipmap:YES];
    }
    if (self.delegate) {
        [self.delegate movieDidDecodeNewFrame:self];
    }
}

- (BOOL) update
{
    return YES;
}

- (GPUImageTimestamp)timeLastChanged
{
    return timeLastChanged;
}

@end
