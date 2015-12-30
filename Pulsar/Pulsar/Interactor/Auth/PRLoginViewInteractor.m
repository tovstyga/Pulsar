//
//  PRLoginViewInteractor.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRLoginViewInteractor.h"

@implementation PRLoginViewInteractor

- (void)loginUser:(NSString *)userName withPassword:(NSString *)password completion:(void(^)(BOOL success))completion
{
    if (completion) {
        completion(YES);
    }
}

@end
