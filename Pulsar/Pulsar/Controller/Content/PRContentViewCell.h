//
//  PRContentViewCell.h
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Article.h"
#import "Media.h"

@class PRContentViewCell;

@protocol PRContentCellDelegate <NSObject>

- (void)shareTwitter:(Article *)article;
- (void)shareFacebook:(Article *)article;
- (void)likeArticle:(Article *)article;
- (void)dislikeArticle:(Article *)article;
- (void)addArticleToFavorite:(Article *)article;
- (void)thumbnailForMedia:(Media *)media completion:(void(^)(UIImage *image, NSError *error))completion;

- (void)willExpandCell:(PRContentViewCell *)cell;
- (void)didExpandCell:(PRContentViewCell *)cell;
- (void)willCollapseCell:(PRContentViewCell *)cell;
- (void)didCollapseCell:(PRContentViewCell *)cell;

@end

@interface PRContentViewCell : UITableViewCell

@property (nonatomic) IBInspectable CGFloat separatorHeight;
@property (strong, nonatomic) Article *article;
@property (weak, nonatomic) id<PRContentCellDelegate> delegate;
@property (nonatomic, readonly) float expandedDelta;

- (void)setMaxTextWidth:(CGFloat)width;
- (void)expandeCell;
- (void)colapseCell;

@end
