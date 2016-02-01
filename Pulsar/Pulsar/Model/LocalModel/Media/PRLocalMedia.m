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

@end
