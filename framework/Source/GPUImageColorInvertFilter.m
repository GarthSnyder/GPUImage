#import "GPUImageColorInvertFilter.h"

NSString *const kGPUImageInvertFragmentShaderString = SHADER_STRING
(
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;

    void main()
    {
        lowp vec4 textureColor = texture2D(inputImage, textureCoordinate);

        gl_FragColor = vec4((1.0 - textureColor.rgb), textureColor.w);
    }
);                                                                    

@implementation GPUImageColorInvertFilter

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageInvertFragmentShaderString;
    }
    return self;
}

@end

