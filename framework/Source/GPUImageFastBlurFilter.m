#import "GPUImageFastBlurFilter.h"

//   Code based on http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

NSString *const kGPUImageFastBlurVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec2 inputImageCoordinate;

    uniform highp float texelWidthOffset; 
    uniform highp float texelHeightOffset; 
    uniform highp float blurSize;

    varying highp vec2 centerTextureCoordinate;
    varying highp vec2 oneStepLeftTextureCoordinate;
    varying highp vec2 twoStepsLeftTextureCoordinate;
    varying highp vec2 oneStepRightTextureCoordinate;
    varying highp vec2 twoStepsRightTextureCoordinate;

    // const float offset[3] = float[]( 0.0, 1.3846153846, 3.2307692308 );

    void main()
    {
        gl_Position = position;

        vec2 firstOffset = vec2(1.3846153846 * texelWidthOffset, 1.3846153846 * texelHeightOffset) * blurSize;
        vec2 secondOffset = vec2(3.2307692308 * texelWidthOffset, 3.2307692308 * texelHeightOffset) * blurSize;

        centerTextureCoordinate = inputImageCoordinate;
        oneStepLeftTextureCoordinate = inputImageCoordinate - firstOffset;
        twoStepsLeftTextureCoordinate = inputImageCoordinate - secondOffset;
        oneStepRightTextureCoordinate = inputImageCoordinate + firstOffset;
        twoStepsRightTextureCoordinate = inputImageCoordinate + secondOffset;
    }
);


NSString *const kGPUImageFastBlurFragmentShaderString = SHADER_STRING
(
    precision highp float;

    uniform sampler2D inputImage;

    varying highp vec2 centerTextureCoordinate;
    varying highp vec2 oneStepLeftTextureCoordinate;
    varying highp vec2 twoStepsLeftTextureCoordinate;
    varying highp vec2 oneStepRightTextureCoordinate;
    varying highp vec2 twoStepsRightTextureCoordinate;

    // const float weight[3] = float[]( 0.2270270270, 0.3162162162, 0.0702702703 );

    void main()
    {
        lowp vec4 fragmentColor = texture2D(inputImage, centerTextureCoordinate) * 0.2270270270;
        fragmentColor += texture2D(inputImage, oneStepLeftTextureCoordinate) * 0.3162162162;
        fragmentColor += texture2D(inputImage, oneStepRightTextureCoordinate) * 0.3162162162;
        fragmentColor += texture2D(inputImage, twoStepsLeftTextureCoordinate) * 0.0702702703;
        fragmentColor += texture2D(inputImage, twoStepsRightTextureCoordinate) * 0.0702702703;

        gl_FragColor = fragmentColor;
    }
);

@implementation GPUImageFastBlurFilter

@synthesize blurPasses = _blurPasses;
@dynamic blurSize;

- (id) init
{
    if (self = [super init]) 
    {
        stageOne = [[GPUImageFilter alloc] init];
        stageOne.program.vertexShader = kGPUImageFastBlurVertexShaderString;
        stageOne.program.fragmentShader = kGPUImageFastBlurFragmentShaderString;
        
        self.program.vertexShader = kGPUImageFastBlurVertexShaderString;
        self.program.fragmentShader = kGPUImageFastBlurFragmentShaderString;
        
        self.program.inputImage = stageOne;        
        self.blurSize = 1.0;
        self.blurPasses = 1;
    }
    return self;
}

- (BOOL) update
{
    [stageOne.inputImage update];
    GLsize pSize = stageOne.inputImage.backingStore.size;
    [stageOne setValue:[NSNumber numberWithFloat:(1.0/pSize.width)] forKey:@"texelWidthOffset"];
    [stageOne setValue:[NSNumber numberWithFloat:0.0] forKey:@"texelHeightOffset"];
    [self.program setValue:[NSNumber numberWithFloat:(1.0/pSize.height)] forKey:@"texelHeightOffset"];
    [self.program setValue:[NSNumber numberWithFloat:0.0] forKey:@"texelWidthOffset"];
    return [super update];
}

- (void) setInputImage:(id <GPUImageSource>)img
{
    stageOne.inputImage = img;
}

- (void) setBlurSize:(CGFloat)blurSize 
{
    _blurSize = blurSize;
    NSNumber *blurfl = [NSNumber numberWithFloat:blurSize];
    [stageOne setValue:blurfl forKey:@"blurSize"];
    [self.program setValue:blurfl forKey:@"blurSize"];
}

- (BOOL) render
{
    [super render];
    id <GPUImageSource> savedParent = stageOne.inputImage;
    stageOne.inputImage = self;
    for (int i = 1; i < _blurPasses; i++) {
        [stageOne render];
        [super render];
    }
    stageOne.inputImage = savedParent;
    return YES;
}

@end

