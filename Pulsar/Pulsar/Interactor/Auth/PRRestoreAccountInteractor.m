//
//  PRRestoreAccountInteractor.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRestoreAccountInteractor.h"
#import "PRDataProvider.h"
#import "PRErrorDescriptor.h"

@implementation PRRestoreAccountInteractor

@synthesize validator;

- (BOOL)validateEmail:(NSString *)email
{
    return [self.validator validateEmail:email];
}

- (void)restoreAccountForEmail:(NSString *)email completion:(void (^)(BOOL, NSString *))completion
{
    [self.dataProvider sendNewPasswordOnEmail:email completion:^(NSError *error) {
        if (completion) {
            error ? completion(NO, [self.errorDescriptor descriptionForError:error]) : completion(YES, nil);
        }
    }];
}


@end
