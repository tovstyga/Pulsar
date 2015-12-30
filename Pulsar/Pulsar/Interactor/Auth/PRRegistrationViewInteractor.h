//
//  PRRegistrationViewInteractor.h
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREmailValidator.h"
#import "RPRegistrationViewInteractorProtocol.h"

@interface PRRegistrationViewInteractor : NSObject<RPRegistrationViewInteractorProtocol>

@property (strong, nonatomic) PREmailValidator *validator;

@end
