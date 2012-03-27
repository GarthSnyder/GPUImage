#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImage.h"

@class GPUImageMovieWriter;

@protocol GPUImageMovieWriterDelegate <NSObject>

@optional
-(void)movieWriterDidComplete:(GPUImageMovieWriter *)writer;
-(void)movieWriter:(GPUImageMovieWriter *)writer didFailWithError:(NSError*)error;

@end

@interface GPUImageMovieWriter : GPUImageBase <GPUImageConsumer>
{
    NSURL *movieURL;
	AVAssetWriter *assetWriter;
//	AVAssetWriterInput *assetWriterAudioIn;
	AVAssetWriterInput *assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;    
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    CVPixelBufferRef renderTarget;

    CGSize videoSize;
}

@property (nonatomic, copy) void(^CompletionBlock)(void);
@property (nonatomic, copy) void(^FailureBlock)(NSError*);
@property (nonatomic, assign) id<GPUImageMovieWriterDelegate> delegate;

- (id) initWithMovieURL:(NSURL *)newMovieURL;

// Movie recording
- (void)startRecording;
- (void)finishRecording;

- (BOOL) update;

@end
