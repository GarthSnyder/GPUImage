//  Created by Garth Snyder on 3/15/12.

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// A GPUImageTimestamp is a simple, guaranteed-unique, monotonically increasing
// integer. Used to facilitate flooding of updates through a filter network.

typedef unsigned int GPUImageTimestamp;

extern GPUImageTimestamp GPUImageGetCurrentTimestamp();

// Composite types that are valid as uniforms. (Arrays of these types are
// also valid.)

typedef GLfloat vec2[2];
typedef GLfloat vec3[3];
typedef GLfloat vec4[4];

typedef vec2 mat2[2];
typedef vec3 mat3[3];
typedef vec4 mat4[4];

typedef GLint ivec2[2];
typedef GLint ivec3[3];
typedef GLint ivec4[4];

typedef GLboolean bvec2[2];
typedef GLboolean bvec3[3];
typedef GLboolean bvec4[4];

typedef struct {
    GLint width;
    GLint height;
} GLsize;
