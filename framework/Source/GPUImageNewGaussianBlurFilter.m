#import "GPUImageNewGaussianBlurFilter.h"

NSString *const kGPUImageNewGaussianBlurVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;

    varying highp vec2 texCoord;

    void main() {
        gl_Position = position;
        texCoord = inputTextureCoordinate.xy;
    }
);

// One-dimensional blur, but can be either horizontal or vertical
NSString *const kGPUImageNewGaussianBlurFragmentShaderString = SHADER_STRING
(
    uniform sampler2D inputImageTexture;
    uniform mediump float gaussianValues[24];
    uniform highp float xStep;
    uniform highp float yStep;
    uniform int windowSize;
 
    varying highp vec2 texCoord;

    void main() {
        highp vec2 texPixelStep = vec2(xStep, yStep);
        highp vec2 texLoc = texCoord + texPixelStep * float((windowSize - 1)/2);
        highp vec4 sum = vec4(0.0);
        highp float norm = 0.0;
        highp float gv;

        for (int i = 0; i < windowSize; i++) {
            gv = gaussianValues[i];
            sum += texture2D(inputImageTexture, texLoc) * gv;
            norm += gv;
            texLoc += texPixelStep;
        }

        gl_FragColor = sum/norm;
    }
);

@implementation GPUImageNewGaussianBlurFilter

@synthesize sigma = _sigma;

- (id) initWithFirstStageVertexShaderFromString:(NSString *)firstStageVertexShaderString 
             firstStageFragmentShaderFromString:(NSString *)firstStageFragmentShaderString 
              secondStageVertexShaderFromString:(NSString *)secondStageVertexShaderString
            secondStageFragmentShaderFromString:(NSString *)secondStageFragmentShaderString {
    
    if (!(self = [super initWithFirstStageVertexShaderFromString: 
            firstStageVertexShaderString ? firstStageVertexShaderString : kGPUImageNewGaussianBlurVertexShaderString
        firstStageFragmentShaderFromString:firstStageFragmentShaderString ? firstStageFragmentShaderString : kGPUImageNewGaussianBlurFragmentShaderString
        secondStageVertexShaderFromString:secondStageVertexShaderString ? secondStageVertexShaderString : kGPUImageNewGaussianBlurVertexShaderString
        secondStageFragmentShaderFromString:secondStageFragmentShaderString ? secondStageFragmentShaderString : kGPUImageNewGaussianBlurFragmentShaderString])) {
        return nil;
    }
    
    horizontalWindowSizeUniform = [filterProgram uniformIndex:@"windowSize"];
    horizontalXStepUniform = [filterProgram uniformIndex:@"xStep"];
    horizontalYStepUniform = [filterProgram uniformIndex:@"yStep"];
    horizontalGaussianArrayUniform = [filterProgram uniformIndex:@"gaussianValues"];
    
    verticalWindowSizeUniform = [secondFilterProgram uniformIndex:@"windowSize"];
    verticalXStepUniform = [secondFilterProgram uniformIndex:@"xStep"];
    verticalYStepUniform = [secondFilterProgram uniformIndex:@"yStep"];
    verticalGaussianArrayUniform = [secondFilterProgram uniformIndex:@"gaussianValues"];
    
    self.sigma = 1.0;
    
    return self;
}

- (id)init;
{
    return [self initWithFirstStageVertexShaderFromString:nil
                       firstStageFragmentShaderFromString:nil
                        secondStageVertexShaderFromString:nil
                      secondStageFragmentShaderFromString:nil];
}

#pragma mark Getters and Setters

- (void) calculateGaussianWeights
{
    const GLsizei windowSize = (((int)(_sigma * 6)) / 2) * 2 + 1;
    GLfloat gaussians[24];
    int valuesPerSide = (windowSize - 1) / 2;
    
    // Not really necessary; could let normalization take care of this
    // But useful for debugging since it makes the exact weights evident
    const float factor = 1/sqrtf(2 * M_PI * _sigma * _sigma); 
    
    for (int i = valuesPerSide; i < windowSize; i++) {
 		int n = i - valuesPerSide;
        gaussians[i] = factor * expf(-(n * n)/(2 * _sigma * _sigma));
        if (i > valuesPerSide) {
            gaussians[2 * valuesPerSide - i] = gaussians[i]; // Symmetric distribution
        }
    }
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    
    [filterProgram use];
    glUniform1fv(horizontalGaussianArrayUniform, 24, gaussians);
    glUniform1i(horizontalWindowSizeUniform, windowSize);
    
    [secondFilterProgram use];
    glUniform1fv(verticalGaussianArrayUniform, 64, gaussians);
    glUniform1i(verticalWindowSizeUniform, windowSize);
}

- (void) setupFilterForSize:(CGSize)filterFrameSize
{
    [super setupFilterForSize:filterFrameSize];
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    
    [filterProgram use];
    glUniform1f(horizontalXStepUniform, 1.0/filterFrameSize.width);
    glUniform1f(horizontalYStepUniform, 1.0/filterFrameSize.height);
        
    [secondFilterProgram use];
    glUniform1f(verticalXStepUniform, 1.0/filterFrameSize.width);
    glUniform1f(verticalYStepUniform, 1.0/filterFrameSize.height);
}

- (void) setSigma:(CGFloat)sigma {
    _sigma = sigma;
    [self calculateGaussianWeights];
}

@end
