//
//  PRErrorDescriptor.m
//  Pulsar
//
//  Created by fantom on 05.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRErrorDescriptor.h"

@implementation PRErrorDescriptor

static PRErrorDescriptor *sharedInstance;

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PRErrorDescriptor alloc] init];
    });
    return sharedInstance;
}

- (NSString *)descriptionForError:(NSError *)error
{
    if (error) {
        return [error.userInfo objectForKey:NSLocalizedDescriptionKey];
    }
    return nil;
}

@end
