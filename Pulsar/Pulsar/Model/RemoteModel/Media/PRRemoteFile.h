//
//  PRRemoteFile.h
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteFile : NSObject<PRJsonCompatable>

@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSURL *url;

- (instancetype)initWithName:(NSString *)fileName url:(NSURL *)remoteUrl;

@end
