//
//  PRRemoteCategory.h
//  Pulsar
//
//  Created by fantom on 12.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteCategory : NSObject<PRJsonCompatable>

@property (strong, nonatomic, readonly) NSDate *createdAt;
@property (strong, nonatomic, readonly) NSString *objectId;
@property (strong, nonatomic, readonly) NSDate *updatedAt;
@property (strong, nonatomic, readonly) NSString *name;

@end
