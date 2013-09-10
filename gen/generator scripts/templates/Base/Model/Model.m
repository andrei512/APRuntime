//
//  Model.m
//  Point2Homes
//
//  Created by Andrei Puni on 4/29/13.
//  Copyright (c) 2013 Point2. All rights reserved.
//

#import "Model.h"

#import <MARTNSObject.h>
#import <RTProperty.h>
#import "NSArray+Utils.h"

@implementation Model

- (NSString *)description {
    return [[self asJson] description];
}

+ (instancetype)fromJson:(id)data {
    return [[self new] fromJson:data];
}

- (instancetype)fromJson:(id)data {
    BOOL(^isPrimitive)(NSString *) = ^BOOL(NSString *class) {
        return [class isEqualToString:@"NSString"] ||
               [class isEqualToString:@"NSNumber"] ||
               [class isEqualToString:@"NSDictionary"];
    };
    
    for (NSDictionary *propertyInfo in self.propertyMetadata) {
        NSString *jsonName = propertyInfo[@"json_name"];
        NSString *type = propertyInfo[@"type"];
        NSString *name = propertyInfo[@"name"];
        
        if (data[jsonName] != nil) {
            if (isPrimitive(type)) {
                // primitives
                [self setValue:data[jsonName] forKey:name];
            } else if ([type isEqualToString:@"NSArray"]) {
                // lists
                NSDictionary *of = propertyInfo[@"of"];
                NSString *ofType = (NSString *)of[@"of"];
                if (ofType != nil && isPrimitive(ofType)) {
                    // of primitives
                    [self setValue:data[jsonName] forKey:name];
                } else {
                    // of objects
                    NSArray *listInfo = (NSArray *)data[jsonName];
                    Class ofClass = NSClassFromString(ofType);
                    if (listInfo != nil && [ofClass isSubclassOfClass:Model.class]) {
                        NSArray *list = [listInfo map:^id(id itemData) {
                            return [ofClass fromJson:itemData];
                        }];
                        [self setValue:list forKey:name];
                    }
                }
            } else {
                // objects
                Class class = NSClassFromString(type);
                if ([class isSubclassOfClass:Model.class]) {
                    id object = [class fromJson:data[jsonName]];
                    [self setValue:object forKey:name];
                }
            }
        }
    }
    
    return self;
}

- (NSDictionary *)asJson {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    for (NSDictionary *propertyInfo in self.propertyMetadata) {
        id value = [self valueForKey:propertyInfo[@"name"]];
        if (value) {
            json[propertyInfo[@"json_name"]] = value;
        }
    }
    
    return json;
}

- (NSArray *)propertyMetadata {
    static NSMutableDictionary *store = nil;
    if (store == nil) {
        store = [NSMutableDictionary dictionary];
    }
    
    NSMutableArray *info = store[NSStringFromClass(self.class)];
    if (info == nil) {
        info = [NSMutableArray array];
        store[NSStringFromClass(self.class)] = info;
        
        Class class = self.rt_class;
        do {
            [info addObjectsFromArray:
                 [class.rt_properties map:^id(RTProperty *property) {
                    NSString *type = [[property.typeEncoding stringByReplacingOccurrencesOfString:@"\"" withString:@""]
                                      stringByReplacingOccurrencesOfString:@"@" withString:@""];
                    return @{
                         @"type" : type,
                         @"name" : property.name,
                         @"json_name" : property.name
                     };
                 }]
            ];
            class = [class superclass];
        } while ([class superclass]);
    }   
    
    return info;
}

@end
