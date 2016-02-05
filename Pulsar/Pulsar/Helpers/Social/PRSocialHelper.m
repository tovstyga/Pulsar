//
//  PRSocialHelper.m
//  Pulsar
//
//  Created by fantom on 05.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRSocialHelper.h"
#import <Social/Social.h>
#import "Media.h"

@implementation PRSocialHelper

static int const kTwitterCharLimit = 92;

+ (BOOL)showTwitterShareDialogForArticle:(Article *)article fromViewController:(UIViewController *)viewController
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *composeCotroller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [PRSocialHelper setUpArticle:article composeViewController:composeCotroller limited:YES];
        [viewController presentViewController:composeCotroller animated:YES completion:nil];
        return YES;
    } else {
        return NO;
    }

}

+ (BOOL)showFacebookShareDialogForArticle:(Article *)article fromViewController:(UIViewController *)viewController
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [PRSocialHelper setUpArticle:article composeViewController:composeController limited:NO];
        [viewController presentViewController:composeController animated:YES completion:nil];
        return YES;
    } else {
        return NO;
    }
}

+ (void)setUpArticle:(Article *)article composeViewController:(SLComposeViewController *)composeController limited:(BOOL)limited
{
    NSString *text = [article.annotation length] ? article.annotation : article.text;
    
    if (text.length > kTwitterCharLimit && limited) {
        text = [[text substringToIndex:kTwitterCharLimit - 3] stringByAppendingString:@"..."];
        
    }
    
    [composeController setInitialText:text];
    [composeController addURL:[NSURL URLWithString:@"https://www.apple.com"]]; //url for web
    if (article.image.thumbnail) {
        [composeController addImage:[UIImage imageWithData:article.image.thumbnail]];
    }

}

@end
