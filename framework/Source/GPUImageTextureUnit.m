//  Created by Garth Snyder on 3/17/12.

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageTextureUnit.h"

static NSMutableDictionary *textureUnits;

@implementation GPUImageTextureUnit

@synthesize currentTextureHandle = _currentTextureHandle;
@synthesize textureUnitID = _textureUnitID;

+ (id) unitAtIndex:(GLint)i
{
    if (!textureUnits) {
        textureUnits = [NSMutableDictionary dictionary];
    }
    NSNumber *ixKey = [NSNumber numberWithInt:i];
    GPUImageTextureUnit *unit;
    if (!(unit = [textureUnits objectForKey:ixKey])) {
        unit = [[GPUImageTextureUnit alloc] init];
        [textureUnits setObject:unit forKey:ixKey];
        unit.textureUnitID = GL_TEXTURE0 + i;
    }
    return unit;
}

- (id) init
{
    if (self = [super init]) {
        self.currentTextureHandle = -1;
    }
    return self;
}

- (void) bindTexture:(GPUImageTexture *)texture
{
    glActiveTexture(self.textureUnitID);
    glBindTexture(GL_TEXTURE_2D, texture.textureHandle);
    self.currentTextureHandle = texture.textureHandle;
}

@end
