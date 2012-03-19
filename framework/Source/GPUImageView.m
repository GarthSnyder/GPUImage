#import "GPUImageView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageOpenGLESContext.h"
#import "GPUImageFilter.h"

@interface GPUImageView () 
{
    GPUImageTexture *parent;
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
}

- (void) deriveFrom:(id <GPUImageFlow>)newParent
{
    NSAssert(!parent, @"GPUImageView can have only one parent; underive first.");
    NSAssert([newParent isKindOfClass:[GPUImageTexture class]], 
        @"GPUImageView can only deriveFrom a GPUImageTexture object");
    parent = newParent;
    lastTimeChanged = 0;
    parent.layer = (CAEAGLLayer *)self.layer;
}

- (void) undoDerivationFrom:(id <GPUImageFlow>)oldParent
{
    NSAssert(parent == oldParent, @"GPUImageView: attempt to unparent an object that is not my parent");
    parent = nil;
    lastTimeChanged = 0;
}

- (GPUImageTimestamp) timeLastChanged
{
    return lastTimeChanged;
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

@end
