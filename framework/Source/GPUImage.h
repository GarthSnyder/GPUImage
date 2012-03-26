#import "GPUImageProtocols.h"
#import "GPUImageBase.h"

// A GPUImage is an element that knows how to render itself into a framebuffer,
// and which owns that framebuffer and its associated backing store.
//
// For most purposes, a GPUImage can be thought of as a wrapper for an OpenGL
// texture. But there are some important differences:
//
// 1) A GPUImage can be backed by a renderbuffer instead of a texture.
//
// 2) A GPUImage may or may not have an actual renderbuffer or texture 
//    associated with it, though it always has a (possibly incomplete)
//    specification of what that buffer should look like. GPUImage objects
//    may share buffers if that can be done without violating the update
//    protocol. (Specific OpenGL ES textures and renderbuffers are 
//    represented by subclasses of GPUImageBuffer.)
//
// 3) A GPUImage also has, or can produce on demand, an associated 
//    framebuffer.

@interface GPUImage : GPUImageBase <GPUImageFlow>
{
    GPUImageProvider parent;
    GPUImageTimestamp timeLastChanged;
}

- (BOOL) render;

@end
