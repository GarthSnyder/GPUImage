//
//  Created by Garth Snyder on 3/13/12.
//

#import "GLShader.h"

@interface GLShader ()
{
    NSString *sourceText;
    NSMutableDictionary *_attributes, *_uniforms;
}
@end

@implementation GLShader

@synthesize shaderName = _shaderName;

- (NSArray *) attributes
{
    return [_attributes allKeys];
}

- (NSArray *) uniforms 
{
    return [_uniforms allKeys];
}

- (GLShader *) initWithSourceText:(NSString *)shader;
- (GLShader *) initWithFilename:(NSString *)filename;

- (BOOL) compileAsShaderType:(GLenum)type;
- (void) delete;

@property (nonatomic, readonly) GLint shaderName;
@property (nonatomic, readonly) NSArray *attributes;
@property (nonatomic, readonly) NSArray *uniforms;

@end
