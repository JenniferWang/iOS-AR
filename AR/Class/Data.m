//
//  Data.m
//  AR
//
//  Created by Jiyue Wang on 5/30/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#import "Data.h"

@implementation Data

-(id)initWithCoder:(NSCoder *)coder{
    self=[[Data alloc]init];
    if (self != nil) {
        self.colorX = [coder decodeFloatForKey:@"colorX"];
        self.colorY = [coder decodeFloatForKey:@"colorY"];
        self.colorZ = [coder decodeFloatForKey:@"colorZ"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeFloat:self.colorX forKey:@"colorX"];
    [coder encodeFloat:self.colorY forKey:@"colorY"];
    [coder encodeFloat:self.colorZ forKey:@"colorZ"];
}

-(id)initWithColorX:(float)x Y:(float)y Z:(float)z{
    self = [super init];
    if (self) {
        self.colorX = x;
        self.colorY = y;
        self.colorZ = z;
    }
    return self;
}
@end
