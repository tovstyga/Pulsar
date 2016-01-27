//
//  PRThumbnailMaker.m
//  Pulsar
//
//  Created by fantom on 26.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRThumbnailMaker.h"

@implementation PRThumbnailMaker

+ (UIImage *)thumbnailWithImage:(UIImage *)source
{
    CGSize thumbnailSize = CGSizeMake(80.f, 80.f);
    UIGraphicsBeginImageContext(thumbnailSize);
    [source drawInRect:CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (NSData *)dataWithImage:(UIImage *)source
{
    return UIImagePNGRepresentation(source);
}

@end
