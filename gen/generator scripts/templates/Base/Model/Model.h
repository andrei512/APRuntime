//
//  Model.h
//  Point2Homes
//
//  Created by Andrei Puni on 4/29/13.
//  Copyright (c) 2013 Point2. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+Model.h"

@interface Model : NSObject

// Json referes to Obj-c equivalent to JSON using NSArray, NSDictionary,
// NSString, NSNumber and NSNull
+ (instancetype)fromJson:(id)data;
- (instancetype)fromJson:(id)data;
- (NSDictionary *)asJson;

- (NSArray *)propertyMetadata;

@end
