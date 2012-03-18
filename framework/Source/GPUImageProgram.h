//  This is adapted from Jeff LaMarche's GLProgram OpenGL shader wrapper class
//  from his OpenGL ES 2.0 book. A description of this can be found at his page
//  on the topic:
//
//  http://iphonedevelopment.blogspot.com/2010/11/opengl-es-20-for-ios-chapter-4.html
//
//  Brad Larson: I've extended this to be able to take programs as NSStrings in
//    addition to files, for baked-in shaders.
//  Garth Snyder: Added KVC-style handling of attributes and uniforms, lazy
//    behavior

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "GPUImageShader.h"
#import "GPUImageTexture.h"

// Shortcut for encoding uniform values as NSValues. Argument must be a 
// non-literal value.

#define UNIFORM(x) [NSValue valueWithBytes:&(x) objCType:@encode(typeof(x))]

@interface GPUImageProgram : NSObject
{
    GLint programHandle;
    NSMutableDictionary *uniforms;
    GLint nextTextureUnit;
}

// These are effectively write-only. 
@property (nonatomic) NSString *vertexShader;
@property (nonatomic) NSString *vertexShaderFilename;
@property (nonatomic) NSString *fragmentShader;
@property (nonatomic) NSString *fragmentShaderFilename;

+ (GPUImageProgram *) program;

// This is the primary interface for setting attrs/uniforms and executing.
// Activates (uses) the program and flushes all attribute and uniform values.

- (BOOL) use;

// These utility methods are for clients that want to access the program at
// the lower OpenGL ES level, but they are not needed for typical use.

- (BOOL) link;
- (BOOL) validate;

- (NSString *) logs;
- (NSString *) vertexShaderLog;
- (NSString *) fragmentShaderLog;
- (NSString *) programLog;

// Most programs within GPUImage will use the following standard names
// for inputs and outputs, although this is not required. These properties
// are defined here so that program.inputTexture is always understood and 
// accepted by the compiler without additional configuration. In point of fact,
// all property refs are handled dynamically based on the actual shaders.

@property (nonatomic) GPUImageTexture *inputTexture;
@property (nonatomic) GPUImageTexture *accessoryTexture; // 2nd input
@property (nonatomic) GPUImageTexture *outputTexture;

// This method is generally used only for determining the handles for vertex
// attributes for use in drawing. For uniforms, the general GPUImageProgram
// KVC system should be used (e.g., program.shaderAttr = 3.0).

- (GLint) indexOfAttribute:(NSString *)name;

@end
