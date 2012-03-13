#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

@interface GPUImageOpenGLESContext : NSObject
{
    EAGLContext *_context;
}

@property(readonly, retain) EAGLContext *context;

+ (GPUImageOpenGLESContext *)sharedImageProcessingOpenGLESContext;
+ (void)useImageProcessingContext;
+ (GLint)maximumTextureSizeForThisDevice;
+ (GLint)maximumTextureUnitsForThisDevice;

- (void)presentBufferForDisplay;

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

@end

