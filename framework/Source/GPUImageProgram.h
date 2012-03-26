// GPUImageProgram wraps an OpenGL ES program consisting of two shaders and
// values for the shader uniforms.
// 
// Use KVC-style syntax to set the value of uniforms. For example:
//
//     [program setValue:[NSNumber numberWithFloat:3.0] forKey:@"gamma"]
//
// The values are lazily propagated to OpenGL at the point of use. Furthermore,
// they are dirtiness-tracked so that values are not actually written out
// unless they need to be. 
//
// For sampler uniforms, you can use any object that conforms to the 
// GPUImageSource protocol as a value. GPUImage automatically 
// manages handles and texture units.
//
// Unlike uniforms, vertex attributes are not handled through the KVC system.
// Use indexOfAttribute: to obtain the appropriate handle and call OpenGL
// directly to set up values. (But note that most programs's vertex setups
// will be handled automatically by -draw or -drawWithProgram:.)

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageShader.h"
#import "GPUImage.h"

// Shortcut for encoding uniform values as NSValues. Argument must be 
// non-literal values such as local variables.

#define UNIFORM(x) [NSValue valueWithBytes:&(x) objCType:@encode(typeof(x))]

@interface GPUImageProgram : NSObject
{
    GLint programHandle;
    NSMutableDictionary *uniforms;
    NSMutableDictionary *attributes;
    GLint nextTextureUnit;
}

- (void) setVertexShader:(NSString *)vertexShader;
- (void) setVertexShaderFilename:(NSString *)vertexShaderFilename;
- (void) setFragmentShader:(NSString *)fragmentShader;
- (void) setFragmentShaderFilename:(NSString *)fragmentShaderFilename;

// This is the primary interface for setting attrs/uniforms and executing.
// Activates (uses) the program and flushes all attribute and uniform values.

- (BOOL) use;

// Available, but not needed for typical use.
- (BOOL) link;

- (NSString *) logs;
- (NSString *) vertexShaderLog;
- (NSString *) fragmentShaderLog;
- (NSString *) programLog;

// Most programs within GPUImage will use the following standard names
// for inputs and outputs, although this is not required. These properties
// are defined here so that program.inputTexture is always understood and 
// accepted by the compiler without additional configuration. In point of fact,
// all property refs are handled dynamically based on the actual shaders.

@property (nonatomic) id <GPUImageSource> inputTexture;
@property (nonatomic) id <GPUImageSource> accessoryTexture; // 2nd input
@property (nonatomic) id <GPUImageSource> outputTexture;

// This method is used only for determining the handles for vertex
// attributes for use in drawing. For uniforms, the general GPUImageProgram
// KVC system should be used, e.g.:
//
//     [program setValue:[NSNumber numberWithFloat:3.0] forKey:@"gamma"]

- (GLint) indexOfAttribute:(NSString *)name;

@end
