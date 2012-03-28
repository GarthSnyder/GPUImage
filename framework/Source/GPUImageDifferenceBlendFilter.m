#import "GPUImageDifferenceBlendFilter.h"

NSString *const kGPUImageDifferenceBlendFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;

    void main()
    {
        mediump vec4 textureColor = texture2D(inputImage, textureCoordinate);
        mediump vec4 textureColor2 = texture2D(auxilliaryImage, textureCoordinate);
        gl_FragColor = vec4(abs(textureColor2.rgb - textureColor.rgb), textureColor.a);
    }
);

@implementation GPUImageDifferenceBlendFilter

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageDifferenceBlendFragmentShaderString;
    }
    return self;
}

@end

