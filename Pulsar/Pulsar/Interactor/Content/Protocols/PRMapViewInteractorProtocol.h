//
//  PRMapViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRootInteractorProtocol.h"
#import "PRMapInteractorDelegate.h"

@protocol PRMapViewInteractorProtocol<PRRootInteractorProtocol>

@property (weak, nonatomic) id<PRMapInteractorDelegate> delegate;

- (void)addPointWithName:(NSString *)name longitude:(float)longitude latitude:(float)latitude completion:(void(^)(BOOL success, NSString *errorMessage))completion;

@end
