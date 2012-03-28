#import "GPUImageSharpenFilter.h"

NSString *const kGPUImageSharpenVertexShaderString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;

    uniform float imageWidthFactor; 
    uniform float imageHeightFactor; 
    uniform float sharpness;

    varying vec2 textureCoordinate;
    varying vec2 leftTextureCoordinate;
    varying vec2 rightTextureCoordinate; 
    varying vec2 topTextureCoordinate;
    varying vec2 bottomTextureCoordinate;

    varying float centerMultiplier;
    varying float edgeMultiplier;

    void main()
    {
        gl_Position = position;

        mediump vec2 widthStep = vec2(imageWidthFactor, 0.0);
        mediump vec2 heightStep = vec2(0.0, imageHeightFactor);

        textureCoordinate = inputTextureCoordinate.xy;
        leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
        rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
        topTextureCoordinate = inputTextureCoordinate.xy + heightStep;     
        bottomTextureCoordinate = inputTextureCoordinate.xy - heightStep;

        centerMultiplier = 1.0 + 4.0 * sharpness;
        edgeMultiplier = sharpness;
    }
);

NSString *const kGPUImageSharpenFragmentShaderString = SHADER_STRING
(
    precision highp float;

    varying highp vec2 textureCoordinate;
    varying highp vec2 leftTextureCoordinate;
    varying highp vec2 rightTextureCoordinate; 
    varying highp vec2 topTextureCoordinate;
    varying highp vec2 bottomTextureCoordinate;

    varying highp float centerMultiplier;
    varying highp float edgeMultiplier;

    uniform sampler2D inputTexture;

    void main()
    {
        mediump vec3 textureColor = texture2D(inputTexture, textureCoordinate).rgb;
        mediump vec3 leftTextureColor = texture2D(inputTexture, leftTextureCoordinate).rgb;
        mediump vec3 rightTextureColor = texture2D(inputTexture, rightTextureCoordinate).rgb;
        mediump vec3 topTextureColor = texture2D(inputTexture, topTextureCoordinate).rgb;
        mediump vec3 bottomTextureColor = texture2D(inputTexture, bottomTextureCoordinate).rgb;

        gl_FragColor = vec4((textureColor * centerMultiplier - (leftTextureColor * edgeMultiplier + rightTextureColor * edgeMultiplier + topTextureColor * edgeMultiplier + bottomTextureColor * edgeMultiplier)), texture2D(inputTexture, bottomTextureCoordinate).w);
    }
);

@implementation GPUImageSharpenFilter

@dynamic sharpness;

- (id) init
{
    if (self = [super init]) {
        self.program.vertexShader = kGPUImageSharpenVertexShaderString;
        self.program.fragmentShader = kGPUImageSharpenFragmentShaderString;
        self.sharpness = 0.0;
    }
    return self;
}

- (void) drawWithProgram:(GPUImageProgram *)prog
{
    [self.program setValue:[NSNumber numberWithFloat:(1.0 / self.size.width)] forKey:@"imageWidthFactor"];
    [self.program setValue:[NSNumber numberWithFloat:(1.0 / self.size.height)] forKey:@"imageHeightFactor"];
    [super drawWithProgram:prog];
}

@end

