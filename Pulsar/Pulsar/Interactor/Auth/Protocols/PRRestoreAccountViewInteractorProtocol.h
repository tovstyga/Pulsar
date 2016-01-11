//
//  PRRestoreAccountViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 24.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

@protocol PRRestoreAccountViewInteractorProtocol <NSObject>

- (BOOL)validateEmail:(NSString *)email;
- (void)restoreAccountForEmail:(NSString *)email completion:(void(^)(BOOL success, NSString *errorMessage))completion;

@end