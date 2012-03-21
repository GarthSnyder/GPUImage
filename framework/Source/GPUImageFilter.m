#import "GPUImageFilter.h"
#import "GPUImagePicture.h"

@implementation GPUImageFilter

#pragma mark -
#pragma mark Rendering and drawing

- (id) init
{
    if (self = [super init]) {
        program = [GPUImageProgram program];
    }
    return self;
}

- (BOOL) render
{
    [self takeUnknownParametersFrom:parent];
    [program setValue:parent forKey:@"inputTexture"];
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

#pragma mark -
#pragma mark Attribute and uniform processing

// TODO: Handle attribs and uniforms on behalf of program

@end
