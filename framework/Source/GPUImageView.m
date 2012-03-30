#import "GPUImageView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageFilter.h"
#import <AVFoundation/AVFoundation.h>

@interface GPUImageView () 
{
    GPUImageTimestamp timeLastChanged;
    BOOL hasConverter;
}
- (void) commonInit;
@end

@implementation GPUImageView

@synthesize inputImage = _inputImage;

+ (Class) layerClass 
{
	return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)coder
{
	if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
	return self;
}

- (void) commonInit;
{
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;    
    [GPUImageOpenGLESContext useImageProcessingContext];
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, 
        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];		
	[self addObserver:self forKeyPath:@"frame" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [keyPath isEqualToString:@"frame"]) {
        if (self.inputImage && [self.inputImage respondsToSelector:@selector(releaseCanvas)]) {
            [(id)self.inputImage releaseCanvas];
        }
        timeLastChanged = 0;
    }
}

// We want our supplier to generate a renderbuffer, not a texture.
// But there are a few case (e.g. iterative filters) that can't declare
// themselves as renderbuffers arbitrarily. In those cases, we insert a
// GPUImage converter object into the chain.

- (void) setInputImage:(id <GPUImageSource>)newParent
{
    if (_inputImage != newParent) {
        if ([newParent respondsToSelector:@selector(canUseRenderbuffer)]
            && ![(id)newParent canUseRenderbuffer]) 
        {
            if (!hasConverter) {
                _inputImage = [[GPUImage alloc] init];
                hasConverter = YES;
            }
        } else {
            hasConverter = NO;
        }
        if (hasConverter) {
            [(GPUImage *)_inputImage setInputImage:newParent];
        } else {
            _inputImage = newParent;
        }
        timeLastChanged = 0;
        if ([_inputImage respondsToSelector:@selector(setLayer:)]) {
            [(id)_inputImage setLayer:(CAEAGLLayer *)self.layer];
        }
    }
}

- (BOOL) update
{
    if (!self.inputImage || ![self.inputImage update]) {
        return NO;
    }
    glPushGroupMarkerEXT(0, [[NSString stringWithFormat:@"Update: %s (GPUImageView)", 
        class_getName([self class])] UTF8String]);
    if (timeLastChanged < self.inputImage.timeLastChanged) {
        [GPUImageOpenGLESContext useImageProcessingContext];
        [self.inputImage.canvas bind];
        [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] 
            presentBufferForDisplay];
        timeLastChanged = GPUImageGetCurrentTimestamp();
    }
    glPopGroupMarkerEXT();
    return YES;
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:@"frame"];
}

@end
