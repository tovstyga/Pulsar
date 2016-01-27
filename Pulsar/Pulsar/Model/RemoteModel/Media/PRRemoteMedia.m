//
//  PRRemoteMedia.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteMedia.h"

@implementation PRRemoteMedia

- (instancetype)initWithMediaFileIdentifier:(NSString *)mediaIdentifier
                        thumbnailIdentifier:(NSString *)thumbnailIdentifier
                                contentType:(PRRemoteMediaType)mediaType
{
    self = [super init];
    if (self) {
        _mediaFileIdentifier = mediaIdentifier;
        _thumbnailIdentifier = thumbnailIdentifier;
        _contentType = [self descriptionForMediaType:mediaType];
    }
    return self;
}

- (instancetype)initWithJSON:(id)jsonCompatableOblect
{
    self = [super init];
    if (self && [jsonCompatableOblect isKindOfClass:[NSDictionary class]]) {
        NSDictionary *source = (NSDictionary *)jsonCompatableOblect;
        _contentType = [source objectForKey:@"contentType"];
        _thumbnailIdentifier = [(NSDictionary *)[source objectForKey:@"thumbnail"] objectForKey:@"name"];
        _mediaFileIdentifier = [(NSDictionary *)[source objectForKey:@"content"] objectForKey:@"name"];
    }
    return nil;
}

- (id)toJSONCompatable
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:@{@"contentType" : self.contentType, @"thumbnail" : @{@"__type": @"File", @"name" : self.thumbnailIdentifier}, @"content" : @{@"__type": @"File", @"name" : self.mediaFileIdentifier}}];
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
