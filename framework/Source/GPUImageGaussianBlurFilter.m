#import "GPUImageGaussianBlurFilter.h"

typedef struct {
    GLfloat xStep;
    GLfloat yStep;
} GPUImageBlurStep;

typedef struct {
    GLfloat values[9];
} GPUImageGaussianData;

@interface GPUImageProgram ()
@property (nonatomic) GPUImageBlurStep blurStep;
@property (nonatomic) GPUImageGaussianData gaussianValues;
@end

// Can be either horizontal or vertical blur, depending on blurStep
NSString *const kGPUImageGaussianBlurVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;

    const lowp int GAUSSIAN_SAMPLES = 9;

    uniform highp vec2 blurStep;

    varying highp vec2 textureCoordinate;
    varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];

    void main() {
        gl_Position = position;
        textureCoordinate = inputTextureCoordinate.xy;

        // Calculate the positions for the blur
        lowp int multiplier = 0;
        mediump vec2 blurStep = vec2(0.0, 0.0);
        lowp int samplesPerSide = (GAUSSIAN_SAMPLES - 1) / 2;
        for (lowp int i = -samplesPerSide; i <= samplesPerSide; i++) {
            blurCoordinates[i] = inputTextureCoordinate.xy + blurStep * i;
        }
    }
);

NSString *const kGPUImageGaussianBlurFragmentShaderString = SHADER_STRING
(
    uniform sampler2D inputTexture;

    const lowp int GAUSSIAN_SAMPLES = 9;

    uniform mediump float gaussianValues[9];

    varying highp vec2 textureCoordinate;
    varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];

    void main() {
        highp vec4 sum = vec4(0.0);
        for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
            sum += texture2D(inputTexture, blurCoordinates[i]) * gaussianValues[i];
        }
        gl_FragColor = sum;
    }
);

@implementation GPUImageGaussianBlurFilter

@synthesize blurSize = _blurSize;

- (id) init
{
    if (self = [super init]) {
        self.programOne.vertexShader = kGPUImageGaussianBlurVertexShaderString;
        self.programOne.fragmentShader = kGPUImageGaussianBlurFragmentShaderString;
        self.programTwo.vertexShader = kGPUImageGaussianBlurVertexShaderString;
        self.programTwo.fragmentShader = kGPUImageGaussianBlurFragmentShaderString;
        self.blurSize = 1.0/320.0;
    }
    return self;
}

- (void) setBlurSize:(CGFloat)blurSize
{
    _blurSize = blurSize;
    timeLastChanged = 0;
}

- (BOOL) render 
{
    GPUImageGaussianData gaussians = { 0.05, 0.09, 0.12, 0.15, 0.18, 0.15, 0.12, 0.09, 0.05 };
    GPUImageBlurStep hStep = { _blurSize, 0.0 };
    GPUImageBlurStep vStep = { 0.0, _blurSize };
    
    [self.programOne setValue:UNIFORM(gaussians) forKey:@"gaussianValues"];
    [self.programTwo setValue:UNIFORM(gaussians) forKey:@"gaussianValues"];
    
    [self.programOne setValue:UNIFORM(hStep) forKey:@"blurStep"];
    [self.programTwo setValue:UNIFORM(vStep) forKey:@"blurStep"];
    
    return [super render];
}

@end
