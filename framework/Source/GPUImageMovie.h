#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageBase.h"

@class GPUImageMovie;

@protocol GPUImageMovieDelegate
- movieDidDecodeNewFrame:(GPUImageMovie *)movie;
@end

@interface GPUImageMovie : GPUImageBase <GPUImageUpdating> 
{
  CVPixelBufferRef _currentBuffer;
}

@property (nonatomic, assign) id <GPUImageMovieDelegate> delegate;
@property (readwrite, retain) NSURL *url;

// Initialization and teardown
- (id)initWithURL:(NSURL *)url;

// Movie processing
- (void)enableSynchronizedEncodingUsingMovieWriter:(GPUImageMovieWriter *)movieWriter;
- (void)readNextVideoFrameFromOutput:(AVAssetReaderTrackOutput *)readerVideoTrackOutput;
- (void)readNextAudioSampleFromOutput:(AVAssetReaderTrackOutput *)readerAudioTrackOutput;
- (void)startProcessing;
- (void)endProcessing;
- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer; 

@end
