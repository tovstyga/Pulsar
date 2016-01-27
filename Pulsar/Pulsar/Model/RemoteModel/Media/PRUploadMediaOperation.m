//
//  PRUploadMediaOperation.m
//  Pulsar
//
//  Created by fantom on 26.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRUploadMediaOperation.h"
#import "PRRemoteUploadFileResponse.h"
#import "PRThumbnailMaker.h"
#import "PRNetworkDataProvider.h"
#import "PRRemoteMedia.h"

@implementation PRUploadMediaOperation

static NSString * const kThumbnailFileName = @"thumbnail.png";
static NSString * const kMediaFileName = @"content.png";
static NSString * const kObjectIdentifierKey = @"objectId";

static NSUInteger const kMaxImageSize = 1024 * 1024 * 11;

- (void)main
{
    if (self.cancelled) {
        return;
    }
    __block NSString *mediaIdentidier = nil;
    __weak typeof(self) wSelf = self;
    dispatch_group_t uploadGroup = dispatch_group_create();
    dispatch_group_enter(uploadGroup);
    NSData *imageData = [PRThumbnailMaker dataWithImage:self.uploadImage];
    if ([imageData length] >= kMaxImageSize) {
        dispatch_group_leave(uploadGroup);
    } else {
        [[PRNetworkDataProvider sharedInstance] uploadData:imageData fileName:kMediaFileName success:^(NSData *data, NSURLResponse *response) {
        
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            __block PRRemoteUploadFileResponse *uploadContentResponse = [[PRRemoteUploadFileResponse alloc] initWithJSON:json];
            NSData *thumbnailData = [PRThumbnailMaker dataWithImage:[PRThumbnailMaker thumbnailWithImage:self.uploadImage]];
        
            [[PRNetworkDataProvider sharedInstance] uploadData:thumbnailData fileName:kThumbnailFileName success:^(NSData *data, NSURLResponse *response) {
            
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                PRRemoteUploadFileResponse *uploadThumbnailResponse = [[PRRemoteUploadFileResponse alloc] initWithJSON:json];
                PRRemoteMedia *media = [[PRRemoteMedia alloc] initWithMediaFileIdentifier:uploadContentResponse.resourceIdentifier thumbnailIdentifier:uploadThumbnailResponse.resourceIdentifier contentType:PRRemoteMediaTypeImage];
                __strong  typeof(wSelf) sSelf = wSelf;
                if (sSelf) {
                    media.articlePointer = sSelf.article;
                
                    [[PRNetworkDataProvider sharedInstance] requestNewMedia:media success:^(NSData *data, NSURLResponse *response) {
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                        mediaIdentidier = [json objectForKey:kObjectIdentifierKey];
                        dispatch_group_leave(uploadGroup);
                    } failure:^(NSError *error) {
                        dispatch_group_leave(uploadGroup);
                    }];
                } else {
                    dispatch_group_leave(uploadGroup);
                }
            } failure:^(NSError *error) {
                dispatch_group_leave(uploadGroup);
            }];
        } failure:^(NSError *error) {
            dispatch_group_leave(uploadGroup);
        }];
    }
        
    dispatch_group_wait(uploadGroup, DISPATCH_TIME_FOREVER);
    
    if (self.uploadCompletion) {
        self.uploadCompletion(mediaIdentidier);
    }
}

@end
