#import "GPUImagePosterizeFilter.h"

NSString *const kGPUImagePosterizeFragmentShaderString = SHADER_STRING
( 
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform highp float colorLevels;

    void main()
    {
        highp vec4 textureColor = texture2D(inputImage, textureCoordinate);

        gl_FragColor = floor((textureColor * colorLevels) + vec4(0.5)) / colorLevels;
    }
);

@implementation GPUImagePosterizeFilter

@dynamic colorLevels;

- (id) init
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImagePosterizeFragmentShaderString;
        self.colorLevels = 10;
    }
    return self;
}

@end

