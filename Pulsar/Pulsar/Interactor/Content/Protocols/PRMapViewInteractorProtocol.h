//
//  PRMapViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

@protocol PRMapViewInteractorProtocol<NSObject>

- (void)addPointWithName:(NSString *)name longitude:(float)longitude latitude:(float)latitude completion:(void(^)(BOOL success, NSString *errorMessage))completion;

@end
