//
//  PRCreationViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

@protocol PRCreationViewInteractorProtocol <NSObject>

- (void)loadCategoriesWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (NSArray<NSString *> *)allAvailableCategoriesNames;

@end
