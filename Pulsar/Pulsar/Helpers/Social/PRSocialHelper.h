//
//  PRSocialHelper.h
//  Pulsar
//
//  Created by fantom on 05.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Article.h"
#import <UIKit/UIKit.h>

@interface PRSocialHelper : NSObject

+ (BOOL)showTwitterShareDialogForArticle:(Article *)article fromViewController:(UIViewController *)viewController;

+ (BOOL)showFacebookShareDialogForArticle:(Article *)article fromViewController:(UIViewController *)viewController;

@end
