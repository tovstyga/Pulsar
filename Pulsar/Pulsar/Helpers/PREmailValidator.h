//
//  PREmailValidator.h
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PREmailValidator : NSObject

+ (instancetype)sharedInstance;

- (BOOL)validateEmail:(NSString *)email;
+ (BOOL)validateEmail:(NSString *)email;

@end
