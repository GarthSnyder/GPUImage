#import "GPUImageFilter.h"
#import "GPUImagePicture.h"
#import <objc/runtime.h>

@implementation GPUImageFilter

@synthesize program;
@dynamic inputImage, auxilliaryImage;

- (id) init
{
    if (self = [super init]) {
        self.program = [[GPUImageProgram alloc] init];
    }
    return self;
}

- (BOOL) canUseRenderbuffer 
{
    return YES;
}

// There are a few case (e.g. iterative filters) that can't declare
// themselves as renderbuffers arbitrarily. In those cases, we insert a
// GPUImage converter object into the chain.

- (id <GPUImageSource>) sourceAsRenderbuffer
{
    if (self.canUseRenderbuffer) {
        self.usesRenderbuffer = YES;
        return self;
    } else {
        GPUImage *adapter = [[GPUImage alloc] init];
        adapter.inputImage = self;
        adapter.usesRenderbuffer = YES;
        return adapter;
    }
}

- (void) setUsesRenderbuffer:(BOOL)use
{
    NSAssert(!use || [self canUseRenderbuffer],
        @"This filter cannot use a renderbuffer-based canvas.");
    [super setUsesRenderbuffer:use];
}

#pragma mark -
#pragma mark Rendering and drawing

// Update all texture inputs to our OpenGL progrma

- (BOOL) update
{
    if (!self.program) {
        return NO;
    }
    BOOL needsRender = NO;
    for (id <GPUImageSource> source in self.program.inputImages) {
        if (![source update]) {
            return NO;
        }
        if ([source timeLastChanged] > timeLastChanged) {
            needsRender = YES;
        }
    }
    if (!needsRender && [self.program hasDirtyUniforms]) {
        needsRender = YES;
    }
    if (needsRender) {
        [self adoptParametersFrom:self.inputImage];
        return [self render];
    }
    return YES;
}

- (BOOL) render
{
    glPushGroupMarkerEXT(0, [[NSString stringWithFormat:@"Render: %s (GPUImageFilter)", 
        class_getName([self class])] UTF8String]);
    [self bindAsFramebuffer];
    [self clearFramebuffer];
    [self drawWithProgram:self.program];
    timeLastChanged = GPUImageGetCurrentTimestamp();
    glPopGroupMarkerEXT();
    return YES;
}

- (GPUImageTimestamp) timeLastChanged
{
    return timeLastChanged;
}

- (void) dealloc
{
    NSLog(@"GPUImageFilter dealloc");
}

#pragma mark -
#pragma mark Still image convenience methods

- (UIImage *) imageByFilteringImage:(UIImage *)imageToFilter
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:imageToFilter];
    self.inputImage = stillImageSource;
    [self update];
    UIImage *product = [self getUIImage];
    self.inputImage = nil;
    return product;
}

@end
