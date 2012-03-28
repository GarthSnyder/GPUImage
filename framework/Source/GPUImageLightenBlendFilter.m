#import "GPUImageLightenBlendFilter.h"

NSString *const kGPUImageLightenBlendFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;

    void main()
    {
        lowp vec4 textureColor = texture2D(inputImage, textureCoordinate);
        lowp vec4 textureColor2 = texture2D(auxilliaryImage, textureCoordinate);

        gl_FragColor = max(textureColor, textureColor2);
    }
);

@implementation GPUImageLightenBlendFilter

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageLightenBlendFragmentShaderString;
    }
    return self;
}

@end

