//
//  PRUploadImageManager.h
//  Pulsar
//
//  Created by fantom on 17.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRUploadMediaOperation.h"

@interface PRUploadImageManager : NSObject

- (void)uploadImage:(UIImage *)image articleWithId:(NSString *)articleRemoteId;
- (void)performUploadOperation:(PRUploadMediaOperation *)uploadOperation;

@end
