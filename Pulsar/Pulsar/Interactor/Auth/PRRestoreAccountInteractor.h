//
//  PRRestoreAccountInteractor.h
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRRestoreAccountViewInteractorProtocol.h"
#import "PREmailValidator.h"

@interface PRRestoreAccountInteractor : NSObject<PRRestoreAccountViewInteractorProtocol>

@property (strong, nonatomic) PREmailValidator *validator;

@end
