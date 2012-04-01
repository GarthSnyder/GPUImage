#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageView.h"
#import "GPUImageFilter.h"

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

- (void) setInputImage:(id <GPUImageSource>)newParent
{
    if (_inputImage != newParent) {
        if (newParent) {
            _inputImage = [newParent sourceAsRenderbuffer];
            NSAssert([_inputImage respondsToSelector:@selector(setLayer:)],
                @"Input to GPUImageView must allow setLayer:");
            [(id)_inputImage setLayer:(CAEAGLLayer *)self.layer];
        } else {
            _inputImage = nil;
        }
        timeLastChanged = 0;
    }
}

- (BOOL) update
{
    if (!self.inputImage || ![self.inputImage update]) {
        return NO;
    }
    glPushGroupMarkerEXT(0, [[NSString stringWithFormat:@"Update: %s (GPUImageView)", 
        class_getName([self class])] UTF8String]);
    if (timeLastChanged <= self.inputImage.timeLastChanged) {
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
