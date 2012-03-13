//  This is Jeff LaMarche's GLProgram OpenGL shader wrapper class from his OpenGL ES 2.0 book.
//  A description of this can be found at his page on the topic:
//  http://iphonedevelopment.blogspot.com/2010/11/opengl-es-20-for-ios-chapter-4.html
//
//  Brad Larson: I've extended this to be able to take programs as NSStrings in
//    addition to files, for baked-in shaders.
//  Garth Snyder: Added rudimentary GLSL parsing and KVO-style handling of attributes
//    and uniforms.

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define SHADER_STRINGIZE(x) #x
#define SHADER_STRINGIZE2(x) SHADER_STRINGIZE(x)
#define SHADER_STRING(text) @ SHADER_STRINGIZE2(text)

@interface GLProgram : NSObject 

@property (nonatomic) NSString *vertexShader;
@property (nonatomic) NSString *vertexShaderFilename;
@property (nonatomic) NSString *fragmentShader;
@property (nonatomic) NSString *fragmentShaderFilename;

- (BOOL) use;

// These are both completely optional. In regular use, just use. The
// shader will bind itself automatically.

- (BOOL) link;
- (BOOL) validate;

- (NSString *) vertexShaderLog;
- (NSString *) fragmentShaderLog;
- (NSString *) programLog;

@end
