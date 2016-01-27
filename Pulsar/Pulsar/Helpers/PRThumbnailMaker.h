//
//  PRThumbnailMaker.h
//  Pulsar
//
//  Created by fantom on 26.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PRThumbnailMaker : NSObject

+ (UIImage *)thumbnailWithImage:(UIImage *)source;

+ (NSData *)dataWithImage:(UIImage *)source;

@end
