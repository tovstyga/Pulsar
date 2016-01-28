//
//  PRLocalMedia.h
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PRRemoteFile.h"
#import "PRRemoteMedia.h"

@interface PRLocalMedia : NSObject

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImage *thumbnail;

@property (strong, nonatomic, readonly) NSURL *imageUrl;
@property (strong, nonatomic, readonly) NSURL *thumbnailUrl;

- (instancetype)initWithRemoteMedia:(PRRemoteMedia *)remoteMedia;

@end
