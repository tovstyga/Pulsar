//
//  PRDetailsViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLocalArticle.h"

@protocol PRDetailsViewInteractorProtocol <NSObject>

- (void)loadImageFromUrl:(NSURL *)url completion:(void(^)(UIImage *image, NSString *errorMessage))completion;

- (void)loadMediaContentForArticle:(PRLocalArticle *)article completion:(void(^)(NSString *errorMessage))completion;

- (NSInteger)mediaContentCount;

- (UIImage *)thumbnailForItemAtIndex:(NSInteger)index;

- (void)imageForItemAtIndex:(NSInteger)index completion:(void(^)(UIImage *image, NSString *errorMessage))completion;

@end
