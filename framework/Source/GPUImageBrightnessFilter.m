#import "GPUImageBrightnessFilter.h"

NSString *const kGPUImageBrightnessFragmentShaderString = SHADER_STRING
(
     varying highp vec2 textureCoordinate;
     
     uniform sampler2D inputTexture;
     uniform lowp float brightness;
     
     void main()
     {
         lowp vec4 textureColor = texture2D(inputTexture, textureCoordinate);
         gl_FragColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w);
     }
);

@implementation GPUImageBrightnessFilter

@dynamic brightness;

#pragma mark -
#pragma mark Initialization and teardown

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageBrightnessFragmentShaderString;
        self.brightness = 0.0;
    }
    return self;
}

@end

