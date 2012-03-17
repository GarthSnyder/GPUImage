//
//  GPUImageShaderSymbol.m
//  GPUImage
//
//  Created by Lion User on 3/15/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageShaderSymbol.h"

@implementation GPUImageShaderSymbol

@synthesize name = _name;
@synthesize handle = _handle;
@synthesize type = _type;

- (id) init
{
    self = [super init];
    self.textureUnit = -1;
    return self;
}

@end
