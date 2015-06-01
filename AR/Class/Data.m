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
        self.x = [coder decodeFloatForKey:@"x"];
        self.y = [coder decodeFloatForKey:@"y"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeFloat:self.x forKey:@"x"];
    [coder encodeFloat:self.y forKey:@"y"];
}

-(id)init:(CGPoint)point {
    self = [super init];
    if (self) {
        self.x = point.x;
        self.y = point.y;
    }
    return self;
}
@end
