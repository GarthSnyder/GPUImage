#import "GPUImageContrastFilter.h"

NSString *const kGPUImageContrastFragmentShaderString = SHADER_STRING
( 
     varying highp vec2 textureCoordinate;
     
     uniform sampler2D inputTexture;
     uniform lowp float contrast;
     
     void main()
     {
         lowp vec4 textureColor = texture2D(inputTexture, textureCoordinate);
         
         gl_FragColor = vec4(((textureColor.rgb - vec3(0.5)) * contrast + vec3(0.5)), textureColor.w);
     }
);

@implementation GPUImageContrastFilter

@dynamic contrast;

- (id) init
{
    if (self = [super init]) {
        program.fragmentShader = kGPUImageContrastFragmentShaderString;
        self.contrast = 1.0;
    }
    return self;
}

@end
