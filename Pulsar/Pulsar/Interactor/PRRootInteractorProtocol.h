//
//  PRRootInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 16.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRDataProvider.h"
#import "PRErrorDescriptor.h"

@protocol PRRootInteractorProtocol <NSObject>

@property (strong, nonatomic) PRDataProvider *dataProvider;
@property (strong, nonatomic) PRErrorDescriptor *errorDescriptor;

@end
