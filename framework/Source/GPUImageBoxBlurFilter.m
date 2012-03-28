#import "GPUImageBoxBlurFilter.h"

NSString *const kGPUImageBoxBlurVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec2 inputTextureCoordinate;

    uniform mediump float texelWidthOffset; 
    uniform mediump float texelHeightOffset; 

    varying mediump vec2 centerTextureCoordinate;
    varying mediump vec2 oneStepLeftTextureCoordinate;
    varying mediump vec2 twoStepsLeftTextureCoordinate;
    // varying mediump vec2 threeStepsLeftTextureCoordinate;
    varying mediump vec2 oneStepRightTextureCoordinate;
    varying mediump vec2 twoStepsRightTextureCoordinate;
    // varying mediump vec2 threeStepsRightTextureCoordinate;

    // const float offset[3] = float[]( 0.0, 1.3846153846, 3.2307692308 );

    void main()
    {
        gl_Position = position;

        vec2 firstOffset = vec2(1.5 * texelWidthOffset, 1.5 * texelHeightOffset);
        vec2 secondOffset = vec2(3.5 * texelWidthOffset, 3.5 * texelHeightOffset);
        //     vec2 thirdOffset = vec2(5.5 * texelWidthOffset, 5.5 * texelHeightOffset);

        centerTextureCoordinate = inputTextureCoordinate;
        oneStepLeftTextureCoordinate = inputTextureCoordinate - firstOffset;
        twoStepsLeftTextureCoordinate = inputTextureCoordinate - secondOffset;
        //     threeStepsLeftTextureCoordinate = inputTextureCoordinate - thirdOffset;
        oneStepRightTextureCoordinate = inputTextureCoordinate + firstOffset;
        twoStepsRightTextureCoordinate = inputTextureCoordinate + secondOffset;
        //     threeStepsRightTextureCoordinate = inputTextureCoordinate + thirdOffset;
    }
);

NSString *const kGPUImageBoxBlurFragmentShaderString = SHADER_STRING
(
    precision highp float;

    uniform sampler2D inputImage;

    varying mediump vec2 centerTextureCoordinate;
    varying mediump vec2 oneStepLeftTextureCoordinate;
    varying mediump vec2 twoStepsLeftTextureCoordinate;
    // varying mediump vec2 threeStepsLeftTextureCoordinate;
    varying mediump vec2 oneStepRightTextureCoordinate;
    varying mediump vec2 twoStepsRightTextureCoordinate;
    // varying mediump vec2 threeStepsRightTextureCoordinate;

    void main()
    {
        mediump vec4 fragmentColor = texture2D(inputImage, centerTextureCoordinate) * 0.2;
        fragmentColor += texture2D(inputImage, oneStepLeftTextureCoordinate) * 0.2;
        fragmentColor += texture2D(inputImage, oneStepRightTextureCoordinate) * 0.2;
        fragmentColor += texture2D(inputImage, twoStepsLeftTextureCoordinate) * 0.2;
        fragmentColor += texture2D(inputImage, twoStepsRightTextureCoordinate) * 0.2;
        //     mediump vec4 fragmentColor = texture2D(inputImage, centerTextureCoordinate) * 0.1428;
        //     fragmentColor += texture2D(inputImage, oneStepLeftTextureCoordinate) * 0.1428;
        //     fragmentColor += texture2D(inputImage, oneStepRightTextureCoordinate) * 0.1428;
        //     fragmentColor += texture2D(inputImage, twoStepsLeftTextureCoordinate) * 0.1428;
        //     fragmentColor += texture2D(inputImage, twoStepsRightTextureCoordinate) * 0.1428;

        //     fragmentColor += texture2D(inputImage, threeStepsLeftTextureCoordinate) * 0.1428;
        //     fragmentColor += texture2D(inputImage, threeStepsRightTextureCoordinate) * 0.1428;

        gl_FragColor = fragmentColor;
    }
);

@implementation GPUImageBoxBlurFilter

- (id) init
{
    if (self = [super init]) 
    {
        stageOne = [[GPUImageFilter alloc] init];
        stageOne.program.vertexShader = kGPUImageBoxBlurVertexShaderString;
        stageOne.program.fragmentShader = kGPUImageBoxBlurFragmentShaderString;
        
        self.program.vertexShader = kGPUImageBoxBlurVertexShaderString;
        self.program.fragmentShader = kGPUImageBoxBlurFragmentShaderString;
        
        self.program.inputImage = stageOne;
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

@end
