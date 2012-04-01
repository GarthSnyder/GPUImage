#import "GPUImageGaussianBlurFilter.h"

NSString *const kGPUImageGaussianBlurVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;

    const lowp int GAUSSIAN_SAMPLES = 9;

    uniform highp float texelWidthOffset; 
    uniform highp float texelHeightOffset;
    uniform highp float blurSize;

    varying highp vec2 textureCoordinate;
    varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];

    void main() {
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;

    // Calculate the positions for the blur
    int multiplier = 0;
    highp vec2 blurStep;
    highp vec2 singleStepOffset = vec2(texelHeightOffset, texelWidthOffset) * blurSize;
     
        for (lowp int i = 0; i < GAUSSIAN_SAMPLES; i++) {
            multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
            // Blur in x (horizontal)
            blurStep = float(multiplier) * singleStepOffset;
            blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
        }
    }
);

NSString *const kGPUImageGaussianBlurFragmentShaderString = SHADER_STRING
(
    uniform sampler2D inputImage;

    const lowp int GAUSSIAN_SAMPLES = 9;

    varying highp vec2 textureCoordinate;
    varying highp vec2 blurCoordinates[GAUSSIAN_SAMPLES];

    void main() 
    {
        lowp vec4 sum = vec4(0.0);

        sum += texture2D(inputImage, blurCoordinates[0]) * 0.05;
        sum += texture2D(inputImage, blurCoordinates[1]) * 0.09;
        sum += texture2D(inputImage, blurCoordinates[2]) * 0.12;
        sum += texture2D(inputImage, blurCoordinates[3]) * 0.15;
        sum += texture2D(inputImage, blurCoordinates[4]) * 0.18;
        sum += texture2D(inputImage, blurCoordinates[5]) * 0.15;
        sum += texture2D(inputImage, blurCoordinates[6]) * 0.12;
        sum += texture2D(inputImage, blurCoordinates[7]) * 0.09;
        sum += texture2D(inputImage, blurCoordinates[8]) * 0.05;

        gl_FragColor = sum;
    }
);

@implementation GPUImageGaussianBlurFilter

@synthesize blurSize = _blurSize;

- (id) init
{
    if (self = [super init]) 
    {
        stageOne = [[GPUImageFilter alloc] init];
        stageOne.program.vertexShader = kGPUImageGaussianBlurVertexShaderString;
        stageOne.program.fragmentShader = kGPUImageGaussianBlurFragmentShaderString;
        stageOne.program.delegate = self;
        
        self.program.vertexShader = kGPUImageGaussianBlurVertexShaderString;
        self.program.fragmentShader = kGPUImageGaussianBlurFragmentShaderString;
        self.program.delegate = self;
        
        self.program.inputImage = stageOne;        
        self.blurSize = 1.0;
    }
    return self;
}

// Defer setting size-related parameters as long as possible since sizes are lazy
- (void) programWillDraw:(GPUImageProgram *)prog
{
    GLsize pSize = stageOne.inputImage.canvas.size;
    if (prog == self.program) {
        [prog setValue:[NSNumber numberWithFloat:(1.0/pSize.height)] forKey:@"texelHeightOffset"];
        [prog setValue:[NSNumber numberWithFloat:0.0] forKey:@"texelWidthOffset"];
    } else {
        [prog setValue:[NSNumber numberWithFloat:(1.0/pSize.width)] forKey:@"texelWidthOffset"];
        [prog setValue:[NSNumber numberWithFloat:0.0] forKey:@"texelHeightOffset"];
    }
}

- (void) setInputImage:(id <GPUImageSource>)img
{
    stageOne.inputImage = img;
}

- (void) setBlurSize:(CGFloat)blurSize 
{
    _blurSize = blurSize;
    [stageOne setValue:UNIFORM(blurSize) forKey:@"blurSize"];
    [self.program setValue:UNIFORM(blurSize) forKey:@"blurSize"];
}

@end
