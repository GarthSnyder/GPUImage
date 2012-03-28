#import "GPUImageSoftLightBlendFilter.h"

NSString *const kGPUImageSoftLightBlendFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;

    void main()
    {
        mediump vec4 textureColor = texture2D(inputImage, textureCoordinate);
        mediump vec4 textureColor2 = texture2D(auxilliaryImage, textureCoordinate);
        gl_FragColor = 2.0 * textureColor2 * textureColor + textureColor * textureColor - 2.0 * textureColor * textureColor *textureColor2;
    }
);

@implementation GPUImageSoftLightBlendFilter

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageSoftLightBlendFragmentShaderString;
    }
    return self;
}

@end

