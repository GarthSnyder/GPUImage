#import "GPUImageDissolveBlendFilter.h"

NSString *const kGPUImageDissolveBlendFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D auxilliaryImage;
    uniform lowp float mixturePercent;

    void main()
    {
        lowp vec4 textureColor = texture2D(inputImage, textureCoordinate);
        lowp vec4 textureColor2 = texture2D(auxilliaryImage, textureCoordinate);

        gl_FragColor = mix(textureColor, textureColor2, mixturePercent);
    }
);

@implementation GPUImageDissolveBlendFilter

@dynamic mixturePercent;

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageDissolveBlendFragmentShaderString;
        self.mixturePercent = 0.5;
    }
    return self;
}

@end
