#import "GPUImageColorBurnBlendFilter.h"

NSString *const kGPUImageColorBurnBlendFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;

    void main()
    {
        mediump vec4 textureColor = texture2D(inputImage, textureCoordinate);
        mediump vec4 textureColor2 = texture2D(auxilliaryImage, textureCoordinate);
        mediump vec4 whiteColor = vec4(1.0);
        gl_FragColor = whiteColor - (whiteColor - textureColor) / textureColor2;
    }
);

@implementation GPUImageColorBurnBlendFilter

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageColorBurnBlendFragmentShaderString;
    }
    return self;
}

@end

