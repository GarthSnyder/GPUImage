#import "GPUImageExposureFilter.h"

NSString *const kGPUImageExposureFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform highp float exposure;

    void main()
    {
        highp vec4 textureColor = texture2D(inputImage, textureCoordinate);

        gl_FragColor = vec4(textureColor.rgb * pow(2.0, exposure), textureColor.w);
    }
);

@implementation GPUImageExposureFilter

@dynamic exposure;

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageExposureFragmentShaderString;
        self.exposure = 0.0;
    }
    return self;
}

@end

