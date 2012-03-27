#import "GPUImageMultiplyBlendFilter.h"

NSString *const kGPUImageMultiplyBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputTexture;
 uniform sampler2D inputTexture2;
 
 void main()
 {
    lowp vec4 textureColor = texture2D(inputTexture, textureCoordinate);
    lowp vec4 textureColor2 = texture2D(inputTexture2, textureCoordinate);
    
    gl_FragColor = textureColor * textureColor2;
 }
);

@implementation GPUImageMultiplyBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageMultiplyBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

