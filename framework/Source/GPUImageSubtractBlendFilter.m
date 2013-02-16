#import "GPUImageSubtractBlendFilter.h"

NSString *const kGPUImageSubtractBlendFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;

    void main()
    {
        lowp vec4 textureColor = texture2D(inputImage, textureCoordinate);
        lowp vec4 textureColor2 = texture2D(auxilliaryImage, textureCoordinate);

        gl_FragColor = vec4(textureColor.rgb - textureColor2.rgb, textureColor.a);
    }
 );

@implementation GPUImageSubtractBlendFilter

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageSubtractBlendFragmentShaderString;
    }
    return self;
}

@end

