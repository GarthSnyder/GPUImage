#import "GPUImageFilter.h"
#import "GPUImagePicture.h"

@implementation GPUImageFilter

- (id) init
{
    if (self = [super init]) {
        program = [GPUImageProgram program];
    }
    return self;
}

#pragma mark -
#pragma mark Rendering and drawing

- (BOOL) render
{
    [self takeUnknownParametersFrom:parent];
    program.inputTexture = parent;
    if (![program use] || ![self bindAsFramebuffer]) {
        return NO;
    }
    [self drawWithProgram:program];
    self.timeLastChanged = GPUImageGetCurrentTimestamp();
    return YES;
}

#pragma mark -
#pragma mark Still image convenience methods

- (UIImage *) imageByFilteringImage:(UIImage *)imageToFilter
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:imageToFilter];
    [self deriveFrom:stillImageSource];
    [self update];
    UIImage *product = [self getUIImage];
    [self deriveFrom:nil];
    return product;
}

@end
