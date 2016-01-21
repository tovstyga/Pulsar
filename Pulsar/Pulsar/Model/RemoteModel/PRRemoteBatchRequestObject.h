//
//  PRRemoteBatchRequestObject.h
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteBatchRequestObject : NSObject<PRJsonCompatable>

@property (nonatomic, strong, readonly) NSString *method;
@property (nonatomic, strong, readonly) NSString *remoteClass;
@property (nonatomic, strong, readonly) NSDictionary *body;

- (instancetype)initWithMethod:(NSString *)method targetClass:(NSString *)remoteClass body:(NSDictionary *)body;

@end
