//  Created by Garth Snyder on 3/15/12.

// A GPUImageTimestamp is a simple, guaranteed-unique, monotonically increasing
// integer. Used to facilitate flooding of updates through a filter network.

typedef unsigned int GPUImageTimestamp;

extern GPUImageTimestamp GPUImageGetCurrentTimestamp();

// Composite types that are valid as uniforms. (Arrays of these types are
// also valid.)

typedef struct {
    GLfloat x;
    GLfloat y;
} vec2;

typedef struct {
    vec2 a;
    vec2 b;
} mat2;

typedef struct {
    GLfloat x;
    GLfloat y;
    GLfloat z;
} vec3;

typedef struct {
    vec3 a;
    vec3 b;
    vec3 c;
} mat3;

typedef struct {
    GLfloat x;
    GLfloat y;
    GLfloat z;
    GLfloat a;
} vec4;

typedef struct {
    vec4 a;
    vec4 b;
    vec4 c;
    vec4 d;
} mat4;

typedef struct {
    GLint x;
    GLint y;
} ivec2;

typedef struct {
    GLint x;
    GLint y;
    GLint z;
} ivec3;

typedef struct {
    GLint x;
    GLint y;
    GLint z;
    GLint a;
} ivec4;

typedef struct {
    GLboolean x;
    GLboolean y;
} bvec2;

typedef struct {
    GLboolean x;
    GLboolean y;
    GLboolean z;
} bvec3;

typedef struct {
    GLboolean x;
    GLboolean y;
    GLboolean z;
    GLboolean a;
} bvec4;

typedef struct {
    GLint width;
    GLint height;
} GLsize;
