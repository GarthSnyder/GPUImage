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
// If you use the default -draw method, two triangles will be set up and drawn
// for you automatically. Otherwise, use indexOfAttribute: to obtain the 
// appropriate handles and call OpenGL directly to set up values.

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GPUImageShader.h"
#import "GPUImageProtocols.h"

// Shortcut for encoding uniform values as NSValues. Argument must be 
// non-literal values such as local variables.

#define UNIFORM(x) ([NSValue valueWithBytes:&(x) objCType:@encode(typeof(x))])

@class GPUImageProgram;

@protocol GPUImageProgramDelegate 
- (void) programWillDraw:(GPUImageProgram *)prog;
@end

@interface GPUImageProgram : NSObject
{
    GLint programHandle;
    NSMutableDictionary *uniforms;
    NSMutableDictionary *attributes;
    GLint nextTextureUnit;
}

@property (assign, nonatomic) id <GPUImageProgramDelegate> delegate;

- (void) setVertexShader:(NSString *)vertexShader;
- (void) setVertexShaderFilename:(NSString *)vertexShaderFilename;
- (void) setFragmentShader:(NSString *)fragmentShader;
- (void) setFragmentShaderFilename:(NSString *)fragmentShaderFilename;

// Basic two-triangle drawing - includes use
- (void) draw;
- (void) drawWithOrientation:(GPUImageOutputOrientation)orientation textureCoordinates:(const GLfloat *)t;
- (void) drawWithVertices:(const GLfloat *)v textureCoordinates:(const GLfloat *)t;

// This is the primary interface for setting attrs/uniforms and executing.
// Activates (uses) the program and flushes all attribute and uniform values.
- (BOOL) use;

// Available, but not needed for typical use.
- (BOOL) link;

- (BOOL) hasDirtyUniforms;

- (NSString *) logs;
- (NSString *) programLog;

// Most programs within GPUImage will use the following standard names
// for inputs, although this is not required. These properties
// are defined here so that program.inputImage is always understood and 
// accepted by the compiler without additional configuration. This is just
// a simple wrapper for [program setValue:xxx forKey:@"inputImage] et al.

@property (nonatomic, retain) id <GPUImageSource> inputImage;
@property (nonatomic, retain) id <GPUImageSource> auxilliaryImage; // 2nd input

// Returns all uniform values that are GPUImageSources
@property (readonly) NSArray *inputImages;

// This method is used only for determining the handles for vertex
// attributes for use in drawing. For uniforms, the general GPUImageProgram
// KVC system should be used, e.g.:
//
//     [program setValue:[NSNumber numberWithFloat:3.0] forKey:@"gamma"]

- (GLint) indexOfAttribute:(NSString *)name;

@end
