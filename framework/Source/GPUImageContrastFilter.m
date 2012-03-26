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

@synthesize contrast = _contrast;

- (id) init;
{
    if (self = [super init]) {
        self.program.fragmentShader = kGPUImageContrastFragmentShaderString;
        self.contrast = 1.0;
    }
    return self;
}

- (void) setContrast:(GLfloat)contrast
{
    _contrast = contrast;
    [self.program setValue:[NSNumber numberWithFloat:contrast] forKey:@"contrast"];
}

@end
