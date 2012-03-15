#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

@interface GPUImageOpenGLESContext : NSObject
{
}

@property(readonly) EAGLContext *context;

+ (GPUImageOpenGLESContext *)sharedImageProcessingOpenGLESContext;
+ (void)useImageProcessingContext;
+ (GLint)maximumTextureSizeForThisDevice;
+ (GLint)maximumTextureUnitsForThisDevice;

- (void)presentBufferForDisplay;

@end

