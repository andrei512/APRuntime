//
//  Request.m
//  Point2Homes
//
//  Created by Andrei Puni on 7/15/13.
//  Copyright (c) 2013 Point2. All rights reserved.
//

#import "Request.h"

@implementation Request

+ (instancetype)request {
    Request *request = [self new];
    
    return request;
}

- (NSDictionary *)serializedInput {
    return [self.input asJson];
}

- (NSDictionary *)generateRequestBody {
    return @{
             kVersion : @"1.1",
             kMethod : self.methodName,
             kParams : [self serializedInput]
    };
}

- (NSURL *)generateUrl {
    NSString *urlPath = [NSString stringWithFormat:@"%@/%@/%@", self.serverBaseURL, self.serviceName, self.methodName];
    return [NSURL URLWithString:urlPath];
}

- (void)runRequest {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self generateRequestBody]
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:NULL];
    
    NSString *postDataLengthString = [[NSString alloc] initWithFormat:@"%d", [jsonData length]];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[self generateUrl]];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:jsonData];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:postDataLengthString forHTTPHeaderField:@"Content-Length"];
    
    self.requestOperation = [[AFJSONRequestOperation alloc] initWithRequest:urlRequest];
    __block Request *selfb = self;
    
    [self.requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *request, id response) {
        if (response[@"error"] != nil) {
            NSError *error = [NSError errorWithDomain:@"JSON-RPC Error"
                                                 code:kServiceErrorCode
                                             userInfo:response[@"error"]];

            if (selfb.onError != nil) {
                selfb.onError(error);
            }
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Model *responseModel = [selfb.outputClass fromJson:response[@"result"]];
                
                if (selfb.onSucces != nil) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        selfb.onSucces(responseModel);
                    });
                }
            });
        }

        selfb.requestOperation = nil;
    }
                                                 failure:^(AFHTTPRequestOperation *request, NSError *error) {
                                                     // -999 code is used for canceled requests
                                                     if (error.code != -999 && selfb.onError) {
                                                         selfb.onError(error);
                                                     }
                                                     
                                                     selfb.requestOperation = nil;
                                                 }];
    
    [self.requestOperation start];
}

- (void)cancelRequest {
    [self.requestOperation cancel];
    self.requestOperation = nil;
}

@end
