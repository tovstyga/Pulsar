//
//  PRLocalMedia.m
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLocalMedia.h"
#import "PRDataProvider.h"

@implementation PRLocalMedia

- (instancetype)initWithRemoteMedia:(PRRemoteMedia *)remoteMedia
{
    self = [super init];
    if (self) {
        _thumbnailUrl = remoteMedia.thumbnailFile.url;
        _imageUrl = remoteMedia.mediaFile.url;
    }
    return self;
}

//- (UIImage *)image
//{
//    if (!_image) {
//        __block UIImage *template;
//        _image = template;
//        [[PRDataProvider sharedInstance] loadDataFromUrl:_imageUrl completion:^(NSData *data, NSError *error) {
//            template = [UIImage imageWithData:data];
//        }];
//    }
//    return _image;
//}
//
//- (UIImage *)thumbnail
//{
//    if (!_thumbnail) {
//        __block UIImage *template;
//        _thumbnail = template;
//        [[PRDataProvider sharedInstance] loadDataFromUrl:_thumbnailUrl completion:^(NSData *data, NSError *error) {
//            template = [UIImage imageWithData:data];
//        }];
//    }
//    return _thumbnail;
//}


@end
