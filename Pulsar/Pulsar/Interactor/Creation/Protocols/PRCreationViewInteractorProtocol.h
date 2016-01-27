//
//  PRCreationViewInteractorProtocol.h
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PRCreationViewInteractorProtocol <NSObject>

- (void)publishNewArticleWithTitle:(NSString *)title
                        annotation:(NSString *)annotation
                              text:(NSString *)text
                          gategory:(NSString *)category
                             image:(UIImage *)image
                            images:(NSArray<UIImage *> *)images
                        completion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (void)loadCategoriesWithCompletion:(void(^)(BOOL success, NSString *errorMessage))completion;

- (NSArray<NSString *> *)allAvailableCategoriesNames;

@end
