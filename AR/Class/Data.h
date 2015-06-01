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

@property(nonatomic) float x;
@property(nonatomic) float y;

-(id)init:(CGPoint)point;
@end
