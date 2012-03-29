#import "GPUImageColorMatrixFilter.h"

NSString *const kGPUImageColorMatrixFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;

    uniform lowp mat4 colorMatrix;
    uniform lowp float intensity;

    void main()
    {
        lowp vec4 textureColor = texture2D(inputImage, textureCoordinate);
        lowp vec4 outputColor = textureColor * colorMatrix;

        gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);
    }
);                                                                         

@implementation GPUImageColorMatrixFilter

@dynamic intensity, colorMatrix;

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageColorMatrixFragmentShaderString;
        self.intensity = 1.0;
        self.colorMatrix = (mat4) {
            1.f, 0.f, 0.f, 0.f,
            0.f, 1.f, 0.f, 0.f,
            0.f, 0.f, 1.f, 0.f,
            0.f, 0.f, 0.f, 1.f
        };
    }
    return self;
}

@end
