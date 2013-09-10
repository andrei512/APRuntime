//
//  ModelCoder.h
//  Point2Homes
//
//  Created by Andrei Puni on 4/29/13.
//  Copyright (c) 2013 Point2. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelCoder : NSObject

+ (NSString *)typeMap:(NSString *)class;
+ (void)code:(id)object;

@end
