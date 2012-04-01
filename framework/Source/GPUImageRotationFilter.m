#import "GPUImageRotationFilter.h"

@implementation GPUImageRotationFilter

@synthesize rotationMode = _rotationMode;

- (id) init
{
    if (self = [super init]) {
        self.rotationMode = kGPUImageFlipVertical;
    }
    return self;
}

- (void) setRotationMode:(GPUImageRotationMode)newMode
{
    if (newMode != _rotationMode) {
        _rotationMode = newMode;
        [self releaseCanvas];
    }
}

- (void)adoptParametersFrom:(id<GPUImageSource>)other
{
    // If no explicit size has been specified, inherit in orientation-specific way
    if (!self.size.width || !self.size.height) {
        GLsize newSize = other.canvas.size;
        if ((_rotationMode == kGPUImageRotateLeft) 
            || (_rotationMode == kGPUImageRotateRight)
            || (_rotationMode == kGPUImageRotateRightFlipVertical))
        {
            newSize = (GLsize){newSize.height, newSize.width};
        }
        self.size = newSize;
    }
    [super adoptParametersFrom:other];
}

- (void) draw
{
    static const GLfloat rotationSquareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };

    const GLfloat *texCoords;

    switch (self.rotationMode)
    {
        case kGPUImageRotateLeft: 
            texCoords = rotateLeftTextureCoordinates;
            break;
        case kGPUImageRotateRight: 
            texCoords = rotateRightTextureCoordinates;
            break;
        case kGPUImageFlipHorizonal: 
            texCoords = horizontalFlipTextureCoordinates;
            break;
        case kGPUImageFlipVertical: 
            texCoords = verticalFlipTextureCoordinates;
            break;
        case kGPUImageRotateRightFlipVertical: 
            texCoords = rotateRightVerticalFlipTextureCoordinates;
            break;
        default:
            NSAssert1(NO, @"Bad rotation mode: %d", (int)_rotationMode);
    }

    [self.program drawWithVertices:rotationSquareVertices textureCoordinates:texCoords];
}

@end
