//
//  PRRegistrationViewInteractor.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRegistrationViewInteractor.h"

@implementation PRRegistrationViewInteractor

- (BOOL)validateEmail:(NSString *)email
{
    return [self.validator validateEmail:email];
}

- (void)registrateUser:(NSString *)userName
          withPassword:(NSString *)password
                 email:(NSString *)email
            completion:(void(^)(BOOL success))completion
{
    if (completion) {
        completion(YES);
    }
}

@end
