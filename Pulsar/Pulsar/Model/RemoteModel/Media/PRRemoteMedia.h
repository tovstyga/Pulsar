//
//  PRRemoteMedia.h
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"
#import "PRRemotePointer.h"

typedef NS_ENUM(NSUInteger, PRRemoteMediaType) {
    PRRemoteMediaTypeImage
};


@interface PRRemoteMedia : NSObject<PRJsonCompatable>

@property (strong, nonatomic) PRRemotePointer *articlePointer;

@property (strong, nonatomic, readonly) NSString *contentType;
@property (strong, nonatomic, readonly) NSString *mediaFileIdentifier;
@property (strong, nonatomic, readonly) NSString *thumbnailIdentifier;

- (instancetype)initWithMediaFileIdentifier:(NSString *)mediaIdentifier
                        thumbnailIdentifier:(NSString *)thumbnailIdentifier
                                contentType:(PRRemoteMediaType)mediaType;

@end
