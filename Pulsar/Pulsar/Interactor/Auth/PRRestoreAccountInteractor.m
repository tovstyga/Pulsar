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

- (BOOL)validateEmail:(NSString *)email
{
    return [self.validator validateEmail:email];
}

- (void)restoreAccountForEmail:(NSString *)email completion:(void (^)(BOOL, NSString *))completion
{
    [[PRDataProvider sharedInstance] sendNewPasswordOnEmail:email completion:^(NSError *error) {
        if (completion) {
            error ? completion(NO, [PRErrorDescriptor descriptionForError:error]) : completion(YES, nil);
        }
    }];
}


@end
