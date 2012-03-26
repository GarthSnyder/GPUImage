#import "GPUImageShader.h"

@implementation GPUImageShader

@synthesize handle = _handle;

#pragma mark Initializers

- (GPUImageShader *) initWithSourceText:(NSString *)shader
{
    if (self = [super init]) {
        sourceText = shader;
        _handle = -1;
    }
    return self;
}

- (GPUImageShader *) initWithFilename:(NSString *)filename;
{
    NSArray *extensions = [NSArray arrayWithObjects:@"", @"glsl", @"vsh", @"fsh", nil];
    NSString *foundFile;
    for (NSString *ext in extensions) {
        if ((foundFile = [[NSBundle mainBundle] pathForResource:filename ofType:ext])) {
            return [self initWithSourceText:[NSString stringWithContentsOfFile:foundFile
                encoding:NSUTF8StringEncoding error:nil]];
        }
    }
    return nil;
}

#pragma mark Compilation and handle managment

- (BOOL) compileAsShaderType:(GLenum)type
{
    if (_handle >= 0) {
        return YES;
    }

    GLint status;
    const GLchar *source = (GLchar *)[sourceText UTF8String];
    _handle = glCreateShader(type);
    glShaderSource(_handle, 1, &source, NULL);
    glCompileShader(_handle);
    glGetShaderiv(_handle, GL_COMPILE_STATUS, &status);

    if (status != GL_TRUE) {
        NSLog(@"Shader compile log:\n%@", [self log]);
        [self delete];
    }	
    return status == GL_TRUE;
}

- (NSString *) log 
{
    GLint logLength = 0, charsWritten = 0;
    
    glGetProgramiv(self.handle, GL_INFO_LOG_LENGTH, &logLength);    
    if (logLength < 1) {
        return nil;
    }
    
    char *logBytes = malloc(logLength);
    glGetProgramInfoLog(self.handle, logLength, &charsWritten, logBytes);
    NSString *log = [[NSString alloc] initWithBytes:logBytes 
        length:logLength encoding:NSUTF8StringEncoding];
    free(logBytes);
    return log;
}

- (void) delete
{
    if (_handle >= 0) {
        glDeleteShader(_handle);
    }
    _handle = -1;
}

- (void) dealloc
{
    [self delete];
}

@end
