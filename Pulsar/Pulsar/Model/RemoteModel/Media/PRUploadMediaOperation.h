//
//  PRUploadMediaOperation.h
//  Pulsar
//
//  Created by fantom on 26.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PRRemotePointer.h"

typedef void(^OperationCompletionBlock)(NSString *mediaIdentifier);

@interface PRUploadMediaOperation : NSOperation

@property (strong, nonatomic) UIImage *uploadImage;
@property (strong, nonatomic) PRRemotePointer *article;
@property (copy, nonatomic) OperationCompletionBlock uploadCompletion;

@end
