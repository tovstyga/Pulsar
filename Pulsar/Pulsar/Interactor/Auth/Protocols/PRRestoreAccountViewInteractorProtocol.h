//
//  PRRestoreAccountViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 24.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRootInteractorProtocol.h"
#import "PREmailValidator.h"

@protocol PRRestoreAccountViewInteractorProtocol <PRRootInteractorProtocol>

@property (strong, nonatomic) PREmailValidator *validator;

- (BOOL)validateEmail:(NSString *)email;
- (void)restoreAccountForEmail:(NSString *)email completion:(void(^)(BOOL success, NSString *errorMessage))completion;

@end