#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTextureUnit.h"
#import "GPUImageTexture.h"

static NSMutableArray *textureUnits = nil;
static NSUInteger nextTextureUnit = 0;

// This should really be an OpenGL query, but for some reason the iOS 
// implementation of OpenGL ES doesn't seem to define GL_MAX_TEXTURE_COORDS. 
//
// GL_MAX_TEXTURE_IMAGE_UNITS, GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, and
// GL_MAX_TEXTURE_UNITS are not the numbers we need here, as they're all
// concerned with how many texture units can be simultaneously USED.
// We're just interested in how many texture unit NAMES are available.

static GLint maxTextureUnits = 31;

@implementation GPUImageTextureUnit

@synthesize currentTextureHandle = _currentTextureHandle;
@synthesize textureUnitNumber = _textureUnitNumber;

+ (void) activateScratchUnit
{
    glActiveTexture(GL_TEXTURE31);
}

+ (GPUImageTextureUnit *) textureUnit
{
    if (!textureUnits) {
        textureUnits = [NSMutableArray array];
    }
    if (nextTextureUnit >= maxTextureUnits) {
        nextTextureUnit = 0;
    }
    if ([textureUnits count] > nextTextureUnit) {
        nextTextureUnit++;
        return [textureUnits objectAtIndex:(nextTextureUnit - 1)];
    }
    GPUImageTextureUnit *unit = [[GPUImageTextureUnit alloc] 
        initWithTextureUnitNumber:nextTextureUnit++];
    [textureUnits addObject:unit];
    return unit;
}

- (id) initWithTextureUnitNumber:(NSUInteger)tNum
{
    if (self = [super init]) {
        self.currentTextureHandle = -1;
        self.textureUnitNumber = tNum;
    }
    return self;
}

- (void) bindTexture:(GPUImageTexture *)texture
{
    if (self.currentTextureHandle != texture.handle) {
        glActiveTexture(self.textureUnitNumber + GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture.handle);
        self.currentTextureHandle = texture.handle;
    }
}

@end
