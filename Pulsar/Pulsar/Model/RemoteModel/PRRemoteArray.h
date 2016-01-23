//
//  PRRemoteArray.h
//  Pulsar
//
//  Created by fantom on 22.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

typedef NS_ENUM(NSUInteger, PRRemoteArrayAction) {
    PRRemoteArrayActionAdd,
    PRRemoteArrayActionRemove,
    PRRemoteArrayActionAddUnique
};

@interface PRRemoteArray : NSObject<PRJsonCompatable>

- (instancetype)initWithField:(NSString *)remoteFieldName action:(PRRemoteArrayAction)action objects:(NSArray *)jsonCompatableObjects;

@end
