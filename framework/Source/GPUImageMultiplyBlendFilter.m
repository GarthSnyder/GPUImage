#import "GPUImageMultiplyBlendFilter.h"

NSString *const kGPUImageMultiplyBlendFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;

    void main()
    {
        lowp vec4 textureColor = texture2D(inputImage, textureCoordinate);
        lowp vec4 textureColor2 = texture2D(auxilliaryImage, textureCoordinate);

        gl_FragColor = textureColor * textureColor2;
    }
);

@implementation GPUImageMultiplyBlendFilter

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageMultiplyBlendFragmentShaderString;
    }
    return self;
}

@end

