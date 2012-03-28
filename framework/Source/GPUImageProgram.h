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
#import "GPUImageProtocols.h"

// Shortcut for encoding uniform values as NSValues. Argument must be 
// non-literal values such as local variables.

#define UNIFORM(x) ([NSValue valueWithBytes:&(x) objCType:@encode(typeof(x))])

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
// for inputs, although this is not required. These properties
// are defined here so that program.inputImage is always understood and 
// accepted by the compiler without additional configuration. This is just
// a simple wrapper for [program setValue:xxx forKey:@"inputImage] et al.

@property (nonatomic) id <GPUImageSource> inputImage;
@property (nonatomic) id <GPUImageSource> auxilliaryImage; // 2nd input

// Returns all uniform values that are GPUImageSources
@property (readonly) NSArray *inputImages;

// This method is used only for determining the handles for vertex
// attributes for use in drawing. For uniforms, the general GPUImageProgram
// KVC system should be used, e.g.:
//
//     [program setValue:[NSNumber numberWithFloat:3.0] forKey:@"gamma"]

- (GLint) indexOfAttribute:(NSString *)name;

@end
