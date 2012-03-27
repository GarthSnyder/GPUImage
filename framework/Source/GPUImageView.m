#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageView.h"

@interface GPUImageView () 
{
    GPUImageTimestamp timeLastChanged;
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
        if (parent && [parent respondsToSelector:@selector(releaseBackingStore)]) {
            [(id)parent releaseBackingStore];
        }
        timeLastChanged = 0;
    }
}

- (void) setInputImage:(id <GPUImageSource>)newParent
{
    if (_inputImage != newParent) {
        _inputImage = newParent;
        timeLastChanged = 0;
        if (_inputImage) {
            _inputImage.layer = (CAEAGLLayer *)self.layer;
        }
    }
}

- (BOOL) update
{
    if (!self.inputImage || ![self.inputImage update]) {
        return NO;
    }
    if (self.timeLastChanged < parent.timeLastChanged) {
        [GPUImageOpenGLESContext useImageProcessingContext];
        [self.inputImage.backingStore bind];
        [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] 
            presentBufferForDisplay];
        timeLastChanged = GPUImageGetCurrentTimestamp();
    }
    return YES;
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:@"frame"];
}

@end
