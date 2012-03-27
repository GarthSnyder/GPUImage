#import "GPUImageGrayscaleFilter.h"

@implementation GPUImageGrayscaleFilter

NSString *const kGPUImageLuminanceFragmentShaderString = SHADER_STRING
(
    precision highp float;

    varying vec2 textureCoordinate;

    uniform sampler2D inputTexture;

    const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

    void main()
    {
        float luminance = dot(texture2D(inputTexture, textureCoordinate).rgb, W);

        gl_FragColor = vec4(vec3(luminance), 1.0);
    }
);

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageLuminanceFragmentShaderString;
        self.gamma = 1.0;
    }
    return self;
}

@end
