//
//  GPUImageTexture.h
//  GPUImage
//
//  Created by Lion User on 3/14/12.
//  Copyright (c) 2012 Brad Larson. All rights reserved.
//

#import "GPUImageGraphElement.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface GPUImageTexture : GPUImageGraphElement

@property (nonatomic) CGSize size;
//TODO: color model, replication, interpolation

- (BOOL) knowsSize;

- (int) bytesPerPixel;

- textureASUIImage

- takeUnknownParametersFrom

@end
