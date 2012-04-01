#import "GPUImageUnsharpMaskFilter.h"
#import "GPUImageGaussianBlurFilter.h"

NSString *const kGPUImageUnsharpMaskFragmentShaderString = SHADER_STRING
( 
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D blurredImage; 

    uniform highp float intensity;

    void main()
    {
        lowp vec4 sharpImageColor = texture2D(inputImage, textureCoordinate);
        lowp vec3 blurredImageColor = texture2D(blurredImage, textureCoordinate).rgb;

        gl_FragColor = vec4(sharpImageColor.rgb * intensity + blurredImageColor * (1.0 - intensity), sharpImageColor.a);
        //     gl_FragColor = mix(blurredImageColor, sharpImageColor, intensity);
        //     gl_FragColor = vec4(sharpImageColor.rgb - (blurredImageColor.rgb * intensity), 1.0);
    }
);

@implementation GPUImageUnsharpMaskFilter

@dynamic intensity, blurSize;

- (id) init
{
    if (self = [super init]) 
    {
        self.program.fragmentShader = kGPUImageUnsharpMaskFragmentShaderString;
        blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
        [self.program setValue:blurFilter forKey:@"blurredImage"];
        self.intensity = 1.0;
        self.blurSize = 1.0;
    }
    return self;
}

- (void) setInputImage:(id<GPUImageSource>)inputImage
{
    self.program.inputImage = inputImage;
    blurFilter.inputImage = inputImage;
}

- (void) setBlurSize:(CGFloat)newValue;
{
    blurFilter.blurSize = newValue;
}

- (CGFloat) blurSize
{
    return blurFilter.blurSize;
}

@end