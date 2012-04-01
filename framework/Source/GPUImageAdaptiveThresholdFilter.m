#import "GPUImageAdaptiveThresholdFilter.h"
#import "GPUImageFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImageBoxBlurFilter.h"

NSString *const kGPUImageAdaptiveThresholdFragmentShaderString = SHADER_STRING
( 
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputImage;
    uniform sampler2D blurredImage; 

    void main()
    {
        highp vec4 textureColor = texture2D(inputImage, textureCoordinate);
        highp float localLuminance = texture2D(blurredImage, textureCoordinate).r;
        highp float thresholdResult = step(localLuminance - 0.05, textureColor.r);

        gl_FragColor = vec4(vec3(thresholdResult), textureColor.w);
        //     gl_FragColor = vec4(localLuminance, textureColor.r, 0.0, textureColor.w);
    }
);

@implementation GPUImageAdaptiveThresholdFilter

- (id) init
{
    if (self = [super init])
    {
        GPUImageGrayscaleFilter *grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
        GPUImageBoxBlurFilter *boxBlurFilter = [[GPUImageBoxBlurFilter alloc] init];

        self.program.fragmentShader = kGPUImageAdaptiveThresholdFragmentShaderString;
        boxBlurFilter.inputImage = grayscaleFilter;

        self.program.inputImage = grayscaleFilter;
        [self.program setValue:boxBlurFilter forKey:@"blurredImage"];
    }
    return self;
}

// Normally we'd set this on our own program, but here, we pass it along as
// input to the luminance filter.

- (void) setInputImage:(id <GPUImageSource>)img
{
    [[program valueForKey:@"inputImage"] setValue:img forKey:@"inputImage"];
}

@end
