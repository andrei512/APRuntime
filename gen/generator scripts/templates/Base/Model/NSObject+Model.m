//
//  NSObject+Phoenix.m
//  Clomp
//
//  Created by Andrei on 8/11/12.
//  Copyright (c) 2012 Whatevra. All rights reserved.
//

#import "NSObject+Model.h"
#import "MARTNSObject.h"
#import "RTProperty.h"
#import "APUtils.h"

#ifdef WRITE_MODELS
    #import "ModelCoder.h"
#endif

@implementation NSObject (Model)

#define kPropertyName @"kPropertyName"

- (NSArray *)properties {
    NSMutableArray *properties = [NSMutableArray array];
    
    Class class = self.rt_class;
    do {
        for (RTProperty *property in class.rt_properties) {
            [properties addObject:[property name]];                    
        }
        class = [class superclass];
    } while ([class superclass]);
    
    return properties;
}

- (id)loadFrom:(id)data {
    //memoize the properties lists for each class
    __strong static NSMutableDictionary *propertiesDicts = nil;
    
    if (propertiesDicts == nil) {
        propertiesDicts = [NSMutableDictionary dictionary];
    }
    
    NSArray *properties = [propertiesDicts objectForKey:NSStringFromClass([self class])];
    
    if (properties == nil) {
        properties = [self properties];
        [propertiesDicts setObject:properties forKey:NSStringFromClass([self class])];
    }
    
    for (NSString *propertyName in properties) {
        @try {
            id value = data[propertyName];
            if (value) {
                [self setValue:value
                        forKey:propertyName];
            } else {
                value = data[CamelCaseToUnderscores(propertyName)];
                if (value) {
                    [self setValue:value
                            forKey:propertyName];
                } else {
                    value = data[CapitalizeFirst(propertyName)];
                    if (value) {
                        [self setValue:value
                                forKey:propertyName];
                    }
                }
            }
        }
        @catch (NSException *exception) {
            // silent exception
        }
    }
    
#ifdef WRITE_MODELS
    NSMutableArray *lines = [NSMutableArray array];
    for (NSString *key in data) {
        BOOL propertyExists = NO;
        for (NSString *propertyName in properties) {
            if ([propertyName isEqualToString:key]) {
                propertyExists = YES;
                break;
            }
            if ([propertyName isEqualToString:UnderscoresToCamelCase(key)]) {
                propertyExists = YES;
                break;
            }
        }
        if (propertyExists == NO) {
            NSString *line = [NSString stringWithFormat:@"@property (nonatomic, strong) %@ *%@;",
                              [ModelCoder typeMap:NSStringFromClass([data[key] class])],
                                  UnderscoresToCamelCase(key)];
            [lines addObject:line];
        }
    }
    if (lines.count > 0) {
        NSLog(@"On class %@:\n%@",
              NSStringFromClass([self class]),
              [lines componentsJoinedByString:@"\n"]);
    }
#endif
    
    if ([self respondsToSelector:@selector(customLoadData:)]) {
        [self performSelector:@selector(customLoadData:) withObject:data];
    }
    
    return self;
}

- (id)ashes {
    return [self ashes:NO];
}

- (id)ashes:(BOOL)underscored {
    NSMutableDictionary *ashes = [NSMutableDictionary dictionary];

    Class class = self.rt_class;
    do {
        for (RTProperty *property in class.rt_properties) {
            if ([self valueForKey:[property name]] != nil) {
                if (underscored) { 
                    [ashes setValue:[self valueForKey:[property name]] 
                             forKey:CamelCaseToUnderscores([property name])];
                } else {
                    [ashes setValue:[self valueForKey:[property name]] 
                             forKey:[property name]];
                }
            }
        }
        class = [class superclass];
    } while ([class superclass]);

    return ashes;
}

+ (id)createFrom:(id)data {
    id ret = [self new];
    
    [ret loadFrom:data];
    
    return ret;
}

- (NSString *)className {
    return NSStringFromClass(self.class);
}

@end
