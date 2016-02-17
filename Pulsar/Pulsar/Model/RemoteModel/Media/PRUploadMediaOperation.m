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
#import "PRRemoteFile.h"

@implementation PRUploadMediaOperation

static NSString * const kThumbnailFileName = @"thumbnail.png";
static NSString * const kMediaFileName = @"content.png";
static NSString * const kObjectIdentifierKey = @"objectId";

static NSUInteger const kMaxImageSize = 1024 * 1024 * 11;

- (void)main
{
    if (self.cancelled) {
        if (self.uploadCompletion) {
            self.uploadCompletion(nil);
        }
        self.uploadCompletion = nil;
        self.uploadImage = nil;
        self.article = nil;
        return;
    }
    __block NSString *mediaIdentidier = nil;
    __weak typeof(self) wSelf = self;
    dispatch_group_t uploadGroup = dispatch_group_create();
    dispatch_group_enter(uploadGroup);
    PRThumbnailMaker *thumbnailMaker = [[PRThumbnailMaker alloc] init];
    NSData *imageData = [thumbnailMaker dataWithImage:self.uploadImage];
    if ([imageData length] >= kMaxImageSize) {
        dispatch_group_leave(uploadGroup);
    } else {
        [[PRNetworkDataProvider sharedInstance] uploadData:imageData fileName:kMediaFileName success:^(NSData *data, NSURLResponse *response) {
        
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            __block PRRemoteUploadFileResponse *uploadContentResponse = [[PRRemoteUploadFileResponse alloc] initWithJSON:json];
            NSData *thumbnailData = [thumbnailMaker dataWithImage:[thumbnailMaker thumbnailWithImage:self.uploadImage]];
        
            [[PRNetworkDataProvider sharedInstance] uploadData:thumbnailData fileName:kThumbnailFileName success:^(NSData *data, NSURLResponse *response) {
            
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                PRRemoteUploadFileResponse *uploadThumbnailResponse = [[PRRemoteUploadFileResponse alloc] initWithJSON:json];
                
                PRRemoteFile *thumbnail = [[PRRemoteFile alloc] initWithName:uploadThumbnailResponse.resourceIdentifier url:nil];
                PRRemoteFile *contentFile = [[PRRemoteFile alloc] initWithName:uploadContentResponse.resourceIdentifier url:nil];
                
                PRRemoteMedia *media = [[PRRemoteMedia alloc] initWithMediaFile:contentFile thumbnail:thumbnail contentType:PRRemoteMediaTypeImage];
                
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
    self.uploadCompletion = nil;
    self.uploadImage = nil;
    self.article = nil;
}

@end
