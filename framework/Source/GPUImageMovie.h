#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageBase.h"

@class GPUImageMovie;

@protocol GPUImageMovieDelegate
- movieDidDecodeNewFrame:(GPUImageMovie *)movie;
@end

@interface GPUImageMovie : GPUImageBase <GPUImageSource> 
{
  CVPixelBufferRef _currentBuffer;
}

@property (nonatomic, assign) id <GPUImageMovieDelegate> delegate;
@property (readwrite, retain) NSURL *url;

-(id)initWithURL:(NSURL *)url;
-(void)startProcessing;
-(void)endProcessing;

@end
