//
//  PRContentViewCell.m
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRContentViewCell.h"
#import "PRDataProvider.h"

@interface PRContentViewCell()

@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;
@property (weak, nonatomic) IBOutlet UITextView *cellText;
@property (weak, nonatomic) IBOutlet UILabel *cellCategory;

@property (weak, nonatomic) IBOutlet UIButton *sharingTwitter;
@property (weak, nonatomic) IBOutlet UIButton *sharingFacebook;
@property (weak, nonatomic) IBOutlet UIButton *sharingFavorite;

@property (weak, nonatomic) IBOutlet UIButton *upButton;
@property (weak, nonatomic) IBOutlet UIButton *downButton;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoryToShareConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoryToTitleConstraint;
@property (weak, nonatomic) IBOutlet UIStackView *sharingContainer;

@end

@implementation PRContentViewCell{
    BOOL _sharingOpened;
}

- (void)awakeFromNib {
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOnTitle)];
    [self.cellTitle addGestureRecognizer:tapRecognizer];
    _sharingContainer.alpha = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Accessors

- (void)setArticle:(Article *)article
{
    _article = article;
    if (article.image.thumbnail) {
        [self.cellImage setImage:[UIImage imageWithData:article.image.thumbnail]];
    } else {
        [self.cellImage setImage:[UIImage imageNamed:@"Pulse-icon"]];
        if (article.image.thumbnailURL) {
            __weak typeof(self) wSelf = self;
            [[PRDataProvider sharedInstance] loadThumbnailForMedia:article.image completion:^(UIImage *image, NSError *error) {
                if (!error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(wSelf) sSelf = wSelf;
                        if (sSelf) {
                            [sSelf.cellImage setImage:image];
                        }
                    });
                }
            }];
        }
    }
    self.cellTitle.text = article.title;
    self.cellText.text = article.annotation;
    self.cellCategory.text = article.category.name;
    self.ratingLabel.text = [NSString stringWithFormat:@"%ld", (long)[article.rating integerValue]];
}

#pragma mark - Actions

- (void)clickOnTitle
{
    [self showShare:!_sharingOpened animated:YES];
    _sharingOpened = !_sharingOpened;
}

- (IBAction)shareOnTwitter:(UIButton *)sender
{

}

- (IBAction)shareOnFacebook:(UIButton *)sender
{

}

- (IBAction)saveAsFavorite:(UIButton *)sender
{

}

- (IBAction)upRating:(UIButton *)sender
{

}

- (IBAction)downRating:(UIButton *)sender
{

}

#pragma mark - Internal

- (void)showShare:(BOOL)show animated:(BOOL)animated
{
    self.categoryToShareConstraint.priority = show ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
    self.categoryToTitleConstraint.priority = show ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
    if (animated) {
        if (show) {
            [UIView animateWithDuration:0.3f animations:^{
                [self layoutIfNeeded];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3f animations:^{
                    self.sharingContainer.alpha = 1;
                }];
            }];
        } else {
            [UIView animateWithDuration:0.3f animations:^{
                self.sharingContainer.alpha = 0;
                [self layoutIfNeeded];
            }];
        }
        
    } else {
        self.sharingContainer.alpha = show ? 1 : 0;
        [self layoutIfNeeded];
    }
}

@end
