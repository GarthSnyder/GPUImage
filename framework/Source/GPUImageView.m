#import "GPUImageView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageFilter.h"
#import <AVFoundation/AVFoundation.h>

@interface GPUImageView () 
{
    GPUImage *parent;
    GPUImageTimestamp lastTimeChanged;
}
- (void) commonInit;
@end

@implementation GPUImageView

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
        lastTimeChanged = 0;
    }
}

- (void) deriveFrom:(id <GPUImageSource>)newParent
{
    if (parent != newParent) {
        parent = newParent;
    lastTimeChanged = 0;
        if (parent) {
            parent.layer = (CAEAGLLayer *)self.layer;
        }
    }
}

- (BOOL) update
{
    if (!parent || ![parent update]) {
        return NO;
    }
    if (self.timeLastChanged < parent.timeLastChanged) {
        [GPUImageOpenGLESContext useImageProcessingContext];
        [parent.backingStore bind];
        [[GPUImageOpenGLESContext sharedImageProcessingOpenGLESContext] 
            presentBufferForDisplay];
        lastTimeChanged = GPUImageGetCurrentTimestamp();
    }
    return YES;
}

- (void) dealloc
{
    [self removeObserver:self forKeyPath:@"frame"];
}

@end
