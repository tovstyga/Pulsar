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
#import "PRRemoteFile.h"

typedef NS_ENUM(NSUInteger, PRRemoteMediaType) {
    PRRemoteMediaTypeImage
};


@interface PRRemoteMedia : NSObject<PRJsonCompatable>

@property (strong, nonatomic) PRRemotePointer *articlePointer;

@property (strong, nonatomic, readonly) NSString *objectId;
@property (strong, nonatomic, readonly) NSString *contentType;
@property (strong, nonatomic, readonly) PRRemoteFile *mediaFile;
@property (strong, nonatomic, readonly) PRRemoteFile *thumbnailFile;

- (instancetype)initWithMediaFile:(PRRemoteFile *)mediaFile
                        thumbnail:(PRRemoteFile *)thumbnailFile
                      contentType:(PRRemoteMediaType)mediaType;

@end
