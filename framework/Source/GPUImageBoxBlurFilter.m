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

 uniform sampler2D inputTexture;
 
 varying mediump vec2 centerTextureCoordinate;
 varying mediump vec2 oneStepLeftTextureCoordinate;
 varying mediump vec2 twoStepsLeftTextureCoordinate;
// varying mediump vec2 threeStepsLeftTextureCoordinate;
 varying mediump vec2 oneStepRightTextureCoordinate;
 varying mediump vec2 twoStepsRightTextureCoordinate;
// varying mediump vec2 threeStepsRightTextureCoordinate;
 
 void main()
 {
     mediump vec4 fragmentColor = texture2D(inputTexture, centerTextureCoordinate) * 0.2;
     fragmentColor += texture2D(inputTexture, oneStepLeftTextureCoordinate) * 0.2;
     fragmentColor += texture2D(inputTexture, oneStepRightTextureCoordinate) * 0.2;
     fragmentColor += texture2D(inputTexture, twoStepsLeftTextureCoordinate) * 0.2;
     fragmentColor += texture2D(inputTexture, twoStepsRightTextureCoordinate) * 0.2;
//     mediump vec4 fragmentColor = texture2D(inputTexture, centerTextureCoordinate) * 0.1428;
//     fragmentColor += texture2D(inputTexture, oneStepLeftTextureCoordinate) * 0.1428;
//     fragmentColor += texture2D(inputTexture, oneStepRightTextureCoordinate) * 0.1428;
//     fragmentColor += texture2D(inputTexture, twoStepsLeftTextureCoordinate) * 0.1428;
//     fragmentColor += texture2D(inputTexture, twoStepsRightTextureCoordinate) * 0.1428;
     
//     fragmentColor += texture2D(inputTexture, threeStepsLeftTextureCoordinate) * 0.1428;
//     fragmentColor += texture2D(inputTexture, threeStepsRightTextureCoordinate) * 0.1428;
     
     gl_FragColor = fragmentColor;
 }
);

@implementation GPUImageBoxBlurFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFirstStageVertexShaderFromString:kGPUImageBoxBlurVertexShaderString firstStageFragmentShaderFromString:kGPUImageBoxBlurFragmentShaderString secondStageVertexShaderFromString:kGPUImageBoxBlurVertexShaderString secondStageFragmentShaderFromString:kGPUImageBoxBlurFragmentShaderString]))
    {
		return nil;
    }
    
    verticalPassTexelWidthOffsetUniform = [filterProgram uniformIndex:@"texelWidthOffset"];
    verticalPassTexelHeightOffsetUniform = [filterProgram uniformIndex:@"texelHeightOffset"];
    
    horizontalPassTexelWidthOffsetUniform = [secondFilterProgram uniformIndex:@"texelWidthOffset"];
    horizontalPassTexelHeightOffsetUniform = [secondFilterProgram uniformIndex:@"texelHeightOffset"];

    return self;
}

- (void)setupFilterForSize:(CGSize)filterFrameSize;
{
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1f(verticalPassTexelWidthOffsetUniform, 0.0);
    glUniform1f(verticalPassTexelHeightOffsetUniform, 1.0 / filterFrameSize.height);

    [secondFilterProgram use];
    glUniform1f(horizontalPassTexelWidthOffsetUniform, 1.0 / filterFrameSize.width);
    glUniform1f(horizontalPassTexelHeightOffsetUniform, 0.0);
}

@end

