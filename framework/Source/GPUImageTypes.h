#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// A GPUImageTimestamp is a simple, guaranteed-unique, monotonically increasing
// integer. Used to facilitate flooding of updates through a filter network.

typedef unsigned int GPUImageTimestamp;

GPUImageTimestamp GPUImageGetCurrentTimestamp(void);

// Composite types that are valid as uniforms. (Arrays of these types are
// also valid.)
//
// These have to be wrapped as structs in this weird way because properties
// cannot be array-valued, even if the dimensions are known.

typedef struct {
    GLfloat vec2[2];
} vec2;

typedef struct {
    GLfloat vec3[3];
} vec3;

typedef struct {
    GLfloat vec4[4];
} vec4;

typedef struct {
    vec2 mat2[2];
} mat2;

typedef struct {
    vec3 mat3[3];
} mat3;

typedef struct {
    vec4 mat4[4];
}  mat4;

typedef struct {
    GLfloat ivec2[2];
} ivec2;

typedef struct {
    GLfloat ivec3[3];
} ivec3;

typedef struct {
    GLfloat ivec4[4];
} ivec4;

typedef struct {
    GLfloat bvec2[2];
} bvec2;

typedef struct {
    GLfloat bvec3[3];
} bvec3;

typedef struct {
    GLfloat bvec4[4];
} bvec4;

typedef struct {
    GLint width;
    GLint height;
} GLsize;
