#import <Foundation/Foundation.h>
#import "GPUImageOpenGLESContext.h"

@protocol GPUImageOutputDelegate;

@interface GPUImageOutput : NSObject <GPUImageInput>

@property(readwrite, unsafe_unretained, nonatomic) id<GPUImageOutputDelegate> delegate;
@property(readonly) GLint texture;

@end

@protocol GPUImageOutputDelegate
- (void)newFrameReadyFromTextureOutput:(GPUImageOutput *)callbackTextureOutput;
@end