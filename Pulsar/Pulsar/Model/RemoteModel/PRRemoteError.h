//
//  PRRemoteError.h
//  Pulsar
//
//  Created by fantom on 04.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteError : NSObject<PRJsonCompatable>

@property (nonatomic, readonly) int errorCode;
@property (strong, nonatomic, readonly) NSString *errorDescription;

@end
