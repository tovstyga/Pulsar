//
//  PRRemoteResetPasswordRequest.h
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteResetPasswordRequest : NSObject<PRJsonCompatable>

@property (strong, nonatomic) NSString *email;

- (instancetype)initWithEmail:(NSString *)email;

@end
