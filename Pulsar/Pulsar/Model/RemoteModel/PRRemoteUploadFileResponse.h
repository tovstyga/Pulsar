//
//  PRRemoteUploadFileResponse.h
//  Pulsar
//
//  Created by fantom on 26.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteUploadFileResponse : NSObject<PRJsonCompatable>

@property (strong, nonatomic, readonly) NSURL *resourceUrl;
@property (strong, nonatomic, readonly) NSString *resourceIdentifier;

@end
