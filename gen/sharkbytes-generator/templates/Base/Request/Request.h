//
//  Request.h
//  Point2Homes
//
//  Created by Andrei Puni on 7/15/13.
//  Copyright (c) 2013 Point2. All rights reserved.
//

#import <AFNetworking/AFJSONRequestOperation.h>

#import "Model.h"

#define kVersion @"version"
#define kMethod @"method"
#define kParams @"params"

#define kServiceErrorCode -420

typedef void(^RequestSuccessBlock)(id);
typedef void(^RequestErrorBlock)(NSError *);

@interface Request : NSObject

// Callbacks
@property (nonatomic, copy) RequestSuccessBlock onSucces;
@property (nonatomic, copy) RequestErrorBlock onError;

// Input and Output
@property (nonatomic, strong) Model *input;
@property (nonatomic) Class outputClass;

//
@property (nonatomic, strong) AFJSONRequestOperation *requestOperation;

// URL customization and generation
@property (nonatomic, strong) NSString *serverBaseURL;
@property (nonatomic, strong) NSString *serviceName;
@property (nonatomic, strong) NSString *methodName;

+ (instancetype)request;

- (void)runRequest;
- (void)cancelRequest;

@end
