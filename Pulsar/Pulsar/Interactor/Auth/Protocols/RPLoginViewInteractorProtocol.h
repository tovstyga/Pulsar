//
//  RPLoginViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 24.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRRootInteractorProtocol.h"

@protocol RPLoginViewInteractorProtocol <PRRootInteractorProtocol>

- (void)loginUser:(NSString *)userName withPassword:(NSString *)password completion:(void(^)(BOOL success, NSString *errorMessage))completion;

@end