#import "GPUImageNewGaussianBlurFilter.h"

// Blur in x (horizontal)
NSString *const kGPUImageNewGaussianBlurHorizontalVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;

    const lowp int GAUSSIAN_SAMPLES = 13;

    uniform int texWidth;

    varying highp vec2 neighborCoordinates[GAUSSIAN_SAMPLES];

    void main() {
        gl_Position = position;
        highp vec2 texPixelStep = vec2(1.0/float(texWidth), 0.0);
        highp vec2 texLoc = inputTextureCoordinate.xy - texPixelStep * float((GAUSSIAN_SAMPLES - 1)/2);
        for (int i = 0; i < GAUSSIAN_SAMPLES; i++) {
            neighborCoordinates[i] = texLoc;
            texLoc += texPixelStep;
        }
    }
);

// Blur in y (vertical)
NSString *const kGPUImageNewGaussianBlurVerticalVertexShaderString = SHADER_STRING
(
     attribute vec4 position;
     attribute vec4 inputTextureCoordinate;
     
     const lowp int GAUSSIAN_SAMPLES = 13;
     
     uniform int texHeight;
     
     varying highp vec2 neighborCoordinates[GAUSSIAN_SAMPLES];
     
     void main() {
         gl_Position = position;
         highp vec2 texPixelStep = vec2(1.0/float(texHeight), 0.0);
         highp vec2 texLoc = inputTextureCoordinate.xy - texPixelStep * float((GAUSSIAN_SAMPLES - 1)/2);
         for (int i = 0; i < GAUSSIAN_SAMPLES; i++) {
             neighborCoordinates[i] = texLoc;
             texLoc += texPixelStep;
         }
     }
);

NSString *const kGPUImageNewGaussianBlurFragmentShaderString = SHADER_STRING
(
     const lowp int GAUSSIAN_SAMPLES = 13;
 
     uniform sampler2D inputImageTexture;
     uniform mediump float gaussianValues[GAUSSIAN_SAMPLES];
     
     varying highp vec2 neighborCoordinates[GAUSSIAN_SAMPLES];
     
     void main() {
        highp vec4 sum = vec4(0.0);
        highp float norm = 0.0;
        highp float gv;
        
        for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
            gv = gaussianValues[i];
            sum += texture2D(inputImageTexture, neighborCoordinates[i]) * gv;
            norm += gv;
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
            firstStageVertexShaderString ? firstStageVertexShaderString : kGPUImageNewGaussianBlurHorizontalVertexShaderString
        firstStageFragmentShaderFromString:firstStageFragmentShaderString ? firstStageFragmentShaderString : kGPUImageNewGaussianBlurFragmentShaderString
        secondStageVertexShaderFromString:secondStageVertexShaderString ? secondStageVertexShaderString : kGPUImageNewGaussianBlurVerticalVertexShaderString
        secondStageFragmentShaderFromString:secondStageFragmentShaderString ? secondStageFragmentShaderString : kGPUImageNewGaussianBlurFragmentShaderString])) {
        return nil;
    }
    
    imageWidthUniform = [filterProgram uniformIndex:@"texWidth"];
    horizontalGaussianArrayUniform = [filterProgram uniformIndex:@"gaussianValues"];
    
    imageHeightUniform = [secondFilterProgram uniformIndex:@"texHeight"];
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
    const GLsizei gaussianLength = 13;
    int valuesPerSide = (gaussianLength - 1) / 2;
    
    // Not really necessary; could let normalization take care of this
    const float factor = 1/sqrtf(2 * M_PI * _sigma * _sigma); 
    
    GLfloat gaussians[gaussianLength];
    
    for (int i = valuesPerSide; i < sizeof(gaussians)/sizeof(GLfloat); i++) {
 		int n = i - valuesPerSide;
        gaussians[i] = factor * expf(-(n * n)/(2 * _sigma * _sigma));
        if (i > valuesPerSide) {
            gaussians[2 * valuesPerSide - i] = gaussians[i]; // Symmetric distribution
        }
    }
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1fv(horizontalGaussianArrayUniform, gaussianLength, gaussians);
    
    [secondFilterProgram use];
    glUniform1fv(verticalGaussianArrayUniform, gaussianLength, gaussians);
}

- (void) setupFilterForSize:(CGSize)filterFrameSize
{
    [super setupFilterForSize:filterFrameSize];
    
    [GPUImageOpenGLESContext useImageProcessingContext];
    [filterProgram use];
    glUniform1i(imageWidthUniform, filterFrameSize.width);
    
    [secondFilterProgram use];
    glUniform1i(imageHeightUniform, filterFrameSize.height);
}

- (void) setSigma:(CGFloat)sigma {
    _sigma = sigma;
    [self calculateGaussianWeights];
}

@end
