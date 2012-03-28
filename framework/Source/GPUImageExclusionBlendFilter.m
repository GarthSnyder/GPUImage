#import "GPUImageExclusionBlendFilter.h"

NSString *const kGPUImageExclusionBlendFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;

    void main()
    {
        mediump vec4 textureColor = texture2D(inputImage, textureCoordinate);
        mediump vec4 textureColor2 = texture2D(auxilliaryImage, textureCoordinate);
        gl_FragColor = vec4(textureColor.rgb + textureColor2.rgb - (2.0 * textureColor.rgb * textureColor2.rgb), textureColor.a);
    }
);

@implementation GPUImageExclusionBlendFilter

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageExclusionBlendFragmentShaderString;
    }
    return self;
}

@end

