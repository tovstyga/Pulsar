//
//  PRRestoreAccountInteractor.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRestoreAccountInteractor.h"

@implementation PRRestoreAccountInteractor

- (BOOL)validateEmail:(NSString *)email
{
    return [self.validator validateEmail:email];
}

- (void)restoreAccountForEmail:(NSString *)email
{
    
}


@end
