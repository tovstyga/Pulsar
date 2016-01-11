//
//  PRLoginViewInteractor.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRLoginViewInteractor.h"
#import "PRDataProvider.h"
#import "PRErrorDescriptor.h"

@implementation PRLoginViewInteractor

- (void)loginUser:(NSString *)userName withPassword:(NSString *)password completion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] loginUser:userName password:password completion:^(NSError *error) {
        if (completion) {
            error ? completion(NO, [PRErrorDescriptor descriptionForError:error]) : completion(YES, nil);
        }
    }];
}

@end
