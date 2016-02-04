//
//  PRDetailsViewInteractor.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRDetailsViewInteractor.h"
#import "PRDataProvider.h"
#import "PRErrorDescriptor.h"

@implementation PRDetailsViewInteractor{
    NSArray *_media;
}

- (void)loadThumbnailForMedia:(Media *)media completion:(void(^)(UIImage *image, NSString *errorMessage))completion;
{
    [[PRDataProvider sharedInstance] loadThumbnailForMedia:media completion:^(UIImage *image, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, [PRErrorDescriptor descriptionForError:error]);
            }
        } else {
            if (completion) {
                completion(image, nil);
            }
        }
    }];
}

- (void)loadImageForMedia:(Media *)media completion:(void(^)(UIImage *image, NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] loadContentForMedia:media completion:^(UIImage *image, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, [PRErrorDescriptor descriptionForError:error]);
            }
        } else {
            if (completion) {
                completion(image, nil);
            }
        }
    }];
}

- (void)loadMediaContentForArticle:(Article *)article completion:(void(^)(NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] loadMediaForArticle:article completion:^(NSArray<Media *> *mediaArray, NSError *error) {
        if (error) {
            if (completion) {
                completion([PRErrorDescriptor descriptionForError:error]);
            }
        } else {
            _media = mediaArray;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_group_t loadThumbnailsGorup = dispatch_group_create();
                for (Media *media in mediaArray) {
                    if (media.thumbnailURL) {
                        dispatch_group_enter(loadThumbnailsGorup);
                        [[PRDataProvider sharedInstance] loadThumbnailForMedia:media completion:^(UIImage *image, NSError *error) {
                             dispatch_group_leave(loadThumbnailsGorup);
                        }];
                    }
                }
                
                dispatch_group_wait(loadThumbnailsGorup, DISPATCH_TIME_FOREVER);
                
                if (completion) {
                    completion(nil);
                }
            });
        }
    }];
}

- (NSInteger)mediaContentCount
{
    return [_media count];
}

- (UIImage *)thumbnailForItemAtIndex:(NSInteger)index
{
    if (index >= 0 && index < [_media count]) {
        return [UIImage imageWithData:[(Media *)_media[index] thumbnail]];
    }
    return nil;
}

- (void)imageForItemAtIndex:(NSInteger)index completion:(void(^)(UIImage *image, NSString *errorMessage))completion;
{
    if (index >= 0 && index < [_media count]) {
        if ([(Media *)_media[index] image]) {
            if (completion) {
                completion([UIImage imageWithData:[(Media *)_media[index] image]], nil);
            }
        } else if ([(Media *)_media[index] mediaURL]) {
            [[PRDataProvider sharedInstance] loadContentForMedia:_media[index] completion:^(UIImage *image, NSError *error) {
                if (!error) {
                    if (completion) {
                        completion(image, nil);
                    }
                } else {
                    if (completion) {
                        completion(nil, [PRErrorDescriptor descriptionForError:error]);
                    }
                }
            }];
        } else {
            completion(nil, nil);
        }
    } else {
        if (completion) {
            completion(nil, @"Wrong image index");
        }
    }
}

- (void)likeArticle:(Article *)article completion:(void(^)(NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] likeArticle:article success:^(NSError *error) {
        if (completion) {
            if (error) {
                completion([PRErrorDescriptor descriptionForError:error]);
            } else {
                completion(nil);
            }
        }
    }];
}

- (void)dislikeArticle:(Article *)article completion:(void(^)(NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] dislikeArticle:article success:^(NSError *error) {
        if (completion) {
            if (error) {
                completion([PRErrorDescriptor descriptionForError:error]);
            } else {
                completion(nil);
            }
        }
    }];
}

@end
