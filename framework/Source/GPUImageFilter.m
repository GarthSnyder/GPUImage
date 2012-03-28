#import "GPUImageFilter.h"
#import "GPUImagePicture.h"

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

#pragma mark -
#pragma mark Rendering and drawing

// Update all texture inputs to our OpenGL progrma

- (BOOL) update
{
    BOOL needsRender = NO;
    if (!self.program) {
        return NO;
    }
    for (id <GPUImageSource> source in self.program.inputImages) {
        if (![source update]) {
            return NO;
        }
        if ([source timeLastChanged] > timeLastChanged) {
            needsRender = YES;
        }
    }
    if (needsRender) {
        return [self render];
    }
    return YES;
}

- (BOOL) render
{
    [self adoptParametersFrom:self.inputImage];
    if (![self.program use]) {
        return NO;
    }
    [self bindAsFramebuffer];
    [self drawWithProgram:self.program];
    timeLastChanged = GPUImageGetCurrentTimestamp();
    return YES;
}

- (GPUImageTimestamp) timeLastChanged
{
    return timeLastChanged;
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
