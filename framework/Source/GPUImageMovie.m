#import "GPUImageMovie.h"

@interface GPUImageMovie ()
{
    GPUImageTimestamp timeLastChanged;
}
@end

@implementation GPUImageMovie

@synthesize url = _url;
@synthesize delegate = _delegate;

- (id)initWithURL:(NSURL *)url 
{
    if (!(self = [super init])) 
    {
        return nil;
    }
    
    self.url = url;
    
    return self;
}

- (void)startProcessing 
{
    // AVURLAsset to read input movie (i.e. mov recorded to local storage)
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:self.url options:inputOptions];
    
    // Load the input asset tracks information
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        NSError *error = nil;
        // Check status of "tracks", make sure they were loaded    
        AVKeyValueStatus tracksStatus = [inputAsset statusOfValueForKey:@"tracks" error:&error];
        if (!tracksStatus == AVKeyValueStatusLoaded) {
            // failed to load
            return;
        }
        /* Read video samples from input asset video track */
        AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:inputAsset error:&error];
        
        NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
        [outputSettings setObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]  forKey: (NSString*)kCVPixelBufferPixelFormatTypeKey];
        AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
        
        // Assign the tracks to the reader and start to read
        [reader addOutput:readerVideoTrackOutput];
        if ([reader startReading] == NO) {
            // Handle error
            NSLog(@"Error reading");
        }
        
        while (reader.status == AVAssetReaderStatusReading) 
        {
            
            CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
            if (sampleBufferRef) 
            {
                CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
                _currentBuffer = pixelBuffer;
                [self performSelectorOnMainThread:@selector(processFrame) withObject:nil waitUntilDone:YES];
                
                CMSampleBufferInvalidate(sampleBufferRef);
                CFRelease(sampleBufferRef);
            }
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
