//
//  RPRegistrationViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 24.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

@protocol RPRegistrationViewInteractorProtocol <NSObject>

- (BOOL)validateEmail:(NSString *)email;
- (void)registrateUser:(NSString *)userName withPassword:(NSString *)password email:(NSString *)email completion:(void(^)(BOOL success))completion;

@end
