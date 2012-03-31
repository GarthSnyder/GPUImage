#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTextureUnit.h"
#import "GPUImageTexture.h"

static NSMutableArray *textureUnits = nil;
static NSUInteger nextTextureUnit = 0;
static GLint _maxTextureUnits = -1;
static GLint _lastBoundTextureUnit = -1;

@interface GPUImageTextureUnit ()
+ (void) activateTextureUnit:(GLint)unit;
@end

@implementation GPUImageTextureUnit

@synthesize currentTextureHandle = _currentTextureHandle;
@synthesize textureUnitNumber = _textureUnitNumber;

+ (GPUImageTextureUnit *) textureUnit
{
    if (!textureUnits) {
        textureUnits = [NSMutableArray array];
    }
    if (nextTextureUnit >= self.maxTextureUnits) {
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

+ (void) activateTextureUnit:(GLint)unit
{
    if (_lastBoundTextureUnit != unit) {
        glActiveTexture(GL_TEXTURE0 + unit);
        _lastBoundTextureUnit = unit;
    }
}

+ (void) activateScratchUnit
{
    [self activateTextureUnit:self.maxTextureUnits];
}

+ (GLint) maxTextureUnits
{
    if (_maxTextureUnits < 0) {
        glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &_maxTextureUnits);
        _maxTextureUnits--; // Save one for scratch
    }
    return _maxTextureUnits;
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
        [GPUImageTextureUnit activateTextureUnit:self.textureUnitNumber];
        glBindTexture(GL_TEXTURE_2D, texture.handle);
        self.currentTextureHandle = texture.handle;
    }
}

@end
