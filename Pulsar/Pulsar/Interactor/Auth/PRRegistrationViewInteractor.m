//
//  PRRegistrationViewInteractor.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRegistrationViewInteractor.h"
#import "PRDataProvider.h"
#import "PRErrorDescriptor.h"

@implementation PRRegistrationViewInteractor

- (BOOL)validateEmail:(NSString *)email
{
    return [self.validator validateEmail:email];
}

- (void)registrateUser:(NSString *)userName
          withPassword:(NSString *)password
                 email:(NSString *)email
            completion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] registrateUser:userName password:password email:email completion:^(NSError *error) {
        if (completion) {
            error ? completion(NO, [PRErrorDescriptor descriptionForError:error]) : completion(YES, nil);
        }
    }];
}

@end
