//
//  PRErrorDescriptor.m
//  Pulsar
//
//  Created by fantom on 05.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRErrorDescriptor.h"

@implementation PRErrorDescriptor

+ (NSString *)descriptionForError:(NSError *)error
{
    if (error) {
        return [error.userInfo objectForKey:NSLocalizedDescriptionKey];
    }
    return nil;
}

@end
