#import "GPUImageGammaFilter.h"

NSString *const kGPUImageGammaFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform highp float gamma;

    void main()
    {
        lowp vec4 textureColor = texture2D(inputImage, textureCoordinate);

        gl_FragColor = vec4(pow(textureColor.rgb, vec3(gamma)), textureColor.w);
    }
);

@implementation GPUImageGammaFilter

@dynamic gamma;

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageGammaFragmentShaderString;
        self.gamma = 1.0;
    }
    return self;
}

@end
