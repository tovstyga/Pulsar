//
//  PRRemoteMedia.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteMedia.h"

@implementation PRRemoteMedia

- (instancetype)initWithMediaFile:(PRRemoteFile *)mediaFile
                        thumbnail:(PRRemoteFile *)thumbnailFile
                                contentType:(PRRemoteMediaType)mediaType
{
    self = [super init];
    if (self) {
        _mediaFile = mediaFile;
        _thumbnailFile = thumbnailFile;
        _contentType = [self descriptionForMediaType:mediaType];
    }
    return self;
}

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        NSDictionary *source = (NSDictionary *)jsonCompatableOblect;
        _objectId = [source objectForKey:@"objectId"];
        _contentType = [source objectForKey:@"contentType"];
        _thumbnailFile = [[PRRemoteFile alloc] initWithJSON:[source objectForKey:@"thumbnail"]];
        _mediaFile = [[PRRemoteFile alloc] initWithJSON:[source objectForKey:@"content"]];
    }
    return self;
}

- (id)toJSONCompatable
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:@{@"contentType" : self.contentType, @"thumbnail" : [self.thumbnailFile toJSONCompatable], @"content" : [self.mediaFile toJSONCompatable]}];
    if (self.articlePointer) {
        [result setValue:[self.articlePointer toJSONCompatable] forKey:@"article"];
    }
    return result;
}

#pragma mark - Internal

- (NSString *)descriptionForMediaType:(PRRemoteMediaType)mediaType
{
    switch (mediaType) {
        case PRRemoteMediaTypeImage:
            return @"image/png";
        default:
            return @"image/png";
    }
}

@end
