#import "GPUImageLuminanceThresholdFilter.h"

NSString *const kGPUImageLuminanceThresholdFragmentShaderString = SHADER_STRING
( 
    varying highp vec2 textureCoordinate;

    uniform sampler2D inputTexture;
    uniform highp float threshold;

    const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

    void main()
    {
        highp vec4 textureColor = texture2D(inputTexture, textureCoordinate);
        highp float luminance = dot(textureColor.rgb, W);
        highp float thresholdResult = step(threshold, luminance);

        gl_FragColor = vec4(vec3(thresholdResult), textureColor.w);
    }
);

@implementation GPUImageLuminanceThresholdFilter

@dynamic threshold;

#pragma mark -
#pragma mark Initialization

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageLuminanceThresholdFragmentShaderString;
        self.threshold = 0.5;
    }
    return self;
}

@end

