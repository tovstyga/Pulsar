//
//  PRRemotePointer.h
//  Pulsar
//
//  Created by fantom on 19.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemotePointer : NSObject<PRJsonCompatable>

@property (strong, nonatomic, readonly) NSString *className;
@property (strong, nonatomic, readonly) NSString *objectId;

- (instancetype)initWithClass:(NSString *)remoteClassName remoteObjectId:(NSString *)objectId;

@end
