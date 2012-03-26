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
#pragma mark GPUImageFlow protocol

- (void) deriveFrom:(GPUImageProvider)parent
{
    NSAssert(NO, @"Use pic.image = foo to set the input image for a GPUImagePicture.");
}

- (BOOL) update
{
    if (timeLastChanged > 0) {  // Only render once
        return YES;
    }

    CGSize pointSizeOfImage = [imageSource size];
    CGFloat scaleOfImage = [imageSource scale];
    GLsize pixelSizeOfImage = {scaleOfImage * pointSizeOfImage.width + 0.1, 
        scaleOfImage * pointSizeOfImage.height + 0.1);
    if (self.generatesMipmap) {
        // In order to use auto-generated mipmaps, you need to provide
        // power-of-two textures, so convert to the next largest power of
        // two and stretch to fill.
        NSUInteger powerClosestToWidth = ceil(log2(pixelSizeOfImage.width)) + 0.1;
        NSUInteger powerClosestToHeight = ceil(log2(pixelSizeOfImage.height)) + 0.1;
        pixelSizeOfImage.width = 1 << powerClosestToWidth;
        pixelSizeOfImage.height = 1 << powerClosestToHeight;
    }
    
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
	// Using BGRA extension to pull in video frame data directly
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pixelSizeOfImage.width, 
        pixelSizeOfImage.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);

    if (self.generatesMipmap) {
        glGenerateMipmap(GL_TEXTURE_2D);
    }

    free(imageData);
    timeLastChanged = GPUImageGetCurrentTimestamp();
    return YES;
}

@end
