//
//  PREmailValidator.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PREmailValidator.h"

@implementation PREmailValidator

static PREmailValidator *sharedInstance;

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    } else {
        return [super init];
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PREmailValidator alloc] init];
    });
    return sharedInstance;
}

- (BOOL)validateEmail:(NSString *)email
{
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    
    return [emailTest evaluateWithObject:email];
}

+ (BOOL)validateEmail:(NSString *)email
{
    return [[PREmailValidator sharedInstance] validateEmail:email];
}

@end
