#import "GPUImage3x3ConvolutionFilter.h"

// Override vertex shader to remove dependent texture reads 
NSString *const kGPUImageNearbyTexelSamplingVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;

    uniform highp float imageWidthFactor; 
    uniform highp float imageHeightFactor; 

    varying vec2 textureCoordinate;
    varying vec2 leftTextureCoordinate;
    varying vec2 rightTextureCoordinate;

    varying vec2 topTextureCoordinate;
    varying vec2 topLeftTextureCoordinate;
    varying vec2 topRightTextureCoordinate;

    varying vec2 bottomTextureCoordinate;
    varying vec2 bottomLeftTextureCoordinate;
    varying vec2 bottomRightTextureCoordinate;

    void main()
    {
        gl_Position = position;

        vec2 widthStep = vec2(imageWidthFactor, 0.0);
        vec2 heightStep = vec2(0.0, imageHeightFactor);
        vec2 widthHeightStep = vec2(imageWidthFactor, imageHeightFactor);
        vec2 widthNegativeHeightStep = vec2(imageWidthFactor, -imageHeightFactor);

        textureCoordinate = inputTextureCoordinate.xy;
        leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
        rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;

        topTextureCoordinate = inputTextureCoordinate.xy - heightStep;
        topLeftTextureCoordinate = inputTextureCoordinate.xy - widthHeightStep;
        topRightTextureCoordinate = inputTextureCoordinate.xy + widthNegativeHeightStep;

        bottomTextureCoordinate = inputTextureCoordinate.xy + heightStep;
        bottomLeftTextureCoordinate = inputTextureCoordinate.xy - widthNegativeHeightStep;
        bottomRightTextureCoordinate = inputTextureCoordinate.xy + widthHeightStep;
    }
);

NSString *const kGPUImage3x3ConvolutionFragmentShaderString = SHADER_STRING
(
    precision highp float;

    varying vec2 textureCoordinate;
    varying vec2 leftTextureCoordinate;
    varying vec2 rightTextureCoordinate;

    varying vec2 topTextureCoordinate;
    varying vec2 topLeftTextureCoordinate;
    varying vec2 topRightTextureCoordinate;

    varying vec2 bottomTextureCoordinate;
    varying vec2 bottomLeftTextureCoordinate;
    varying vec2 bottomRightTextureCoordinate;

    uniform sampler2D inputImageTexture;

    uniform mediump mat3 convolutionKernel;

    void main()
    {
        mediump vec4 bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate);
        mediump vec4 bottomLeftColor = texture2D(inputImageTexture, bottomLeftTextureCoordinate);
        mediump vec4 bottomRightColor = texture2D(inputImageTexture, bottomRightTextureCoordinate);
        mediump vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
        mediump vec4 leftColor = texture2D(inputImageTexture, leftTextureCoordinate);
        mediump vec4 rightColor = texture2D(inputImageTexture, rightTextureCoordinate);
        mediump vec4 topColor = texture2D(inputImageTexture, topTextureCoordinate);
        mediump vec4 topRightColor = texture2D(inputImageTexture, topRightTextureCoordinate);
        mediump vec4 topLeftColor = texture2D(inputImageTexture, topLeftTextureCoordinate);

        mediump vec4 resultColor = topLeftColor * convolutionKernel[0][0] + topColor * convolutionKernel[0][1] + topRightColor * convolutionKernel[0][2];
        resultColor += leftColor * convolutionKernel[1][0] + centerColor * convolutionKernel[1][1] + rightColor * convolutionKernel[1][2];
        resultColor += bottomLeftColor * convolutionKernel[2][0] + bottomColor * convolutionKernel[2][1] + bottomRightColor * convolutionKernel[2][2];

        gl_FragColor = resultColor;
    }
);

@implementation GPUImage3x3ConvolutionFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (self = [super init]) {
        program.vertexShader = kGPUImageNearbyTexelSamplingVertexShaderString;
        program.fragmentShader = kGPUImage3x3ConvolutionFragmentShaderString;
        program.delegate = self;
    }
    return self;
}

// Defer setting size-related parameters as long as possible since sizes are lazy
- (void) programWillDraw:(GPUImageProgram *)prog
{
    GLsize pSize = program.inputImage.canvas.size;
    prog[@"imageWidthFactor"] = @(1.0f / pSize.width);
    prog[@"imageHeightFactor"] = @(1.0f / pSize.height);
}

@end
