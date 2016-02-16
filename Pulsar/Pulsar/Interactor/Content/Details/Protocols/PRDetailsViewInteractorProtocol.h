//
//  PRDetailsViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "Article.h"
#import "Media.h"
#import <UIKit/UIKit.h>
#import "PRRootInteractorProtocol.h"

@protocol PRDetailsViewInteractorProtocol <PRRootInteractorProtocol>

- (void)loadThumbnailForMedia:(Media *)media completion:(void(^)(UIImage *image, NSString *errorMessage))completion;

- (void)loadImageForMedia:(Media *)media completion:(void(^)(UIImage *image, NSString *errorMessage))completion;

- (void)loadMediaContentForArticle:(Article *)article completion:(void(^)(NSString *errorMessage))completion;

- (NSInteger)mediaContentCount;

- (UIImage *)thumbnailForItemAtIndex:(NSInteger)index;

- (void)imageForItemAtIndex:(NSInteger)index completion:(void(^)(UIImage *image, NSString *errorMessage))completion;

- (void)likeArticle:(Article *)article completion:(void(^)(NSString *errorMessage))completion;

- (void)dislikeArticle:(Article *)article completion:(void(^)(NSString *errorMessage))completion;

@end
