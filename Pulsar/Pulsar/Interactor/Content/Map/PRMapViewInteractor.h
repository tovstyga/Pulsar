//
//  PRMapViewInteractor.h
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRMapViewInteractorProtocol.h"
#import "PRMapInteractorDelegate.h"

@interface PRMapViewInteractor : NSObject<PRMapViewInteractorProtocol>

@property (weak, nonatomic) id<PRMapInteractorDelegate> delegate;

@end
