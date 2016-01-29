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

- (void)loadImageFromUrl:(NSURL *)url completion:(void(^)(UIImage *image, NSString *errorMessage))completion;
{
    [[PRDataProvider sharedInstance] loadDataFromUrl:url completion:^(NSData *data, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, [PRErrorDescriptor descriptionForError:error]);
            }
        } else {
            if (completion) {
                completion([UIImage imageWithData:data], nil);
            }
        }
    }];
}

- (void)loadMediaContentForArticle:(PRLocalArticle *)article completion:(void(^)(NSString *errorMessage))completion
{
    [[PRDataProvider sharedInstance] loadMediaForArticle:article completion:^(NSArray<PRLocalMedia *> *mediaArray, NSError *error) {
        if (error) {
            if (completion) {
                completion([PRErrorDescriptor descriptionForError:error]);
            }
        } else {
            _media = mediaArray;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_group_t loadThumbnailsGorup = dispatch_group_create();
                for (int i = 0; i < [_media count]; i++) {
                    __block PRLocalMedia *localMedia = _media[i];
                    if (!localMedia.thumbnail && localMedia.thumbnailUrl) {
                        dispatch_group_enter(loadThumbnailsGorup);
                        [[PRDataProvider sharedInstance] loadDataFromUrl:localMedia.thumbnailUrl completion:^(NSData *data, NSError *error) {
                            if (!error) {
                                localMedia.thumbnail = [UIImage imageWithData:data];
                            }
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
        return [(PRLocalMedia *)_media[index] thumbnail];
    }
    return nil;
}

- (void)imageForItemAtIndex:(NSInteger)index completion:(void(^)(UIImage *image, NSString *errorMessage))completion;
{
    if (index >= 0 && index < [_media count]) {
        if ([(PRLocalMedia *)_media[index] image]) {
            if (completion) {
                completion([(PRLocalMedia *)_media[index] image], nil);
            }
        } else if ([(PRLocalMedia *)_media[index] imageUrl]) {
            [[PRDataProvider sharedInstance] loadDataFromUrl:[(PRLocalMedia *)_media[index] imageUrl] completion:^(NSData *data, NSError *error) {
                if (!error) {
                    if (completion) {
                        ((PRLocalMedia *)_media[index]).image = [UIImage imageWithData:data];
                        completion(((PRLocalMedia *)_media[index]).image, nil);
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

@end
