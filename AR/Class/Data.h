//
//  Data.h
//  AR
//
//  Created by Jiyue Wang on 5/30/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Data : NSObject 

@property(nonatomic) float colorX;
@property(nonatomic) float colorY;
@property(nonatomic) float colorZ;

-(id)initWithColorX:(float)x Y:(float)y Z:(float)z;
@end
