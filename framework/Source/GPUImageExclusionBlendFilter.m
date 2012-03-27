#import "GPUImageExclusionBlendFilter.h"

NSString *const kGPUImageExclusionBlendFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputTexture;
 uniform sampler2D inputTexture2;
 
 void main()
 {
     mediump vec4 textureColor = texture2D(inputTexture, textureCoordinate);
     mediump vec4 textureColor2 = texture2D(inputTexture2, textureCoordinate);
     gl_FragColor = textureColor + textureColor2 - (2.0 * textureColor * textureColor2);
 }
);

@implementation GPUImageExclusionBlendFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageExclusionBlendFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}

@end

