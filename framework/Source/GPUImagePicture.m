#import "GPUImagePicture.h"

@interface GPUImagePicture
{
    GPUImageTimestamp timeLastChanged;
}
@end

@implementation GPUImagePicture

@synthesize image = _image;

#pragma mark -
#pragma mark Initialization and teardown

- (id) initWithImage:(UIImage *)img;
{
    if (self = [super init]) {
		self.image = img;
    }
    return self;
}

- (void) setImage:(UIImage *)image
{
    if (image != _image) {
        _image = image;
        timeLastChanged = 0;
    }
}

#pragma mark -
#pragma mark GPUImageUpdating protocol

- (void) deriveFrom:(GPUImageSource)parent
{
    NSAssert(NO, @"Use pic.image = foo to set the input image for a GPUImagePicture.");
}

- (BOOL) update
{
    if (timeLastChanged > 0) {  // Static image - only render once
        return YES;
    }

    CGSize pointSizeOfImage = [imageSource size];
    CGFloat scaleOfImage = [imageSource scale];
    GLsize pixelSizeOfImage = {scaleOfImage * pointSizeOfImage.width + 0.1, 
        scaleOfImage * pointSizeOfImage.height + 0.1);
    
    GLubyte *imageData = (GLubyte *) calloc(pixelSizeOfImage.width *
        pixelSizeOfImage.height * 4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();    
    CGContextRef imageContext = CGBitmapContextCreate(imageData, 
        pixelSizeOfImage.width, pixelSizeOfImage.height, 8, 
        pixelSizeOfImage.width * 4, genericRGBColorspace,  
        kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, pixelSizeOfImage.width, 
        pixelSizeOfImage.height), [newImageSource CGImage]);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    self.usesRenderbuffer = NO;
    self.size = pixelSizeOfImage;
    self.pixType = GL_UNSIGNED_BYTE;
    self.baseFormat = GL_RGBA;

    [GPUImageOpenGLESContext useImageProcessingContext];
    [self createBackingStore]; // Binds
	// Using BGRA extension to pull in data directly
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pixelSizeOfImage.width, 
        pixelSizeOfImage.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);

    if (self.generatesMipmap) {
        [self.backingStore generateMipmap:YES];
    }

    free(imageData);
    timeLastChanged = GPUImageGetCurrentTimestamp();
    return YES;
}

@end
