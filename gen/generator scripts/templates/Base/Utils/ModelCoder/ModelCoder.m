//
//  ModelCoder.m
//  Point2Homes
//
//  Created by Andrei Puni on 4/29/13.
//  Copyright (c) 2013 Point2. All rights reserved.
//

#import "ModelCoder.h"
#import "NSString+Utils.h"
#import "NSObject+Model.h"

@implementation ModelCoder

+ (NSString *)typeMap:(NSString *)class {
    NSDictionary *typeMap = @{
        @"__NSCFArray" : @"NSArray",
        @"__NSCFNumber" : @"NSNumber",
        @"__NSCFString" : @"NSString",
        @"__NSCFDictionary" : @"NSDictionary",
        @"__NSDictionaryI" : @"NSDictionary"
    };
    
    if (typeMap[class]) {
        return typeMap[class];
    }
    return class;
}

+ (void)code:(id)object {
    NSLog(@"object = %@", object);
    
    NSDictionary *dict = [object isKindOfClass:[NSDictionary class]] ?
                        object : [object ashes];
    
    for (NSString *key in dict) {
        NSLog(@"@property (nonatomic, strong) %@ *%@;",
              [self typeMap:NSStringFromClass([dict[key] class])],
              UnderscoresToCamelCase(key));
    }
}

@end
