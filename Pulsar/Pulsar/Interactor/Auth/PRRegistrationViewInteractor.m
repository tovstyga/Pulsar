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

@synthesize validator;

- (BOOL)validateEmail:(NSString *)email
{
    return [self.validator validateEmail:email];
}

- (void)registrateUser:(NSString *)userName
          withPassword:(NSString *)password
                 email:(NSString *)email
            completion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    [self.dataProvider registrateUser:userName password:password email:email completion:^(NSError *error) {
        if (completion) {
            error ? completion(NO, [self.errorDescriptor descriptionForError:error]) : completion(YES, nil);
        }
    }];
}

@end
