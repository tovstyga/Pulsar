//
//  PRContentViewCell.m
//  Pulsar
//
//  Created by fantom on 28.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRContentViewCell.h"
#import "InterestCategory.h"

typedef NS_ENUM(NSUInteger, PRLikeState) {
    PRLikeStateLiked,
    PRLikeStateDisliked,
    PRLikeStateUnknown
};

@interface PRContentViewCell()

@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;
@property (weak, nonatomic) IBOutlet UILabel *cellText;
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

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleToTopLongConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleToTopShortConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textToBottomConstraint;


@end

@implementation PRContentViewCell{
    BOOL _sharingOpened;
    PRLikeState _likeState;
}

static int const kRightBorderMargin = 70;

- (void)awakeFromNib {
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOnTitle)];
    [self.cellTitle addGestureRecognizer:tapRecognizer];
    
    UIView *selectedBackgroundView = [[UIView alloc] init];
    [selectedBackgroundView setBackgroundColor:[UIColor clearColor]];
    [self setSelectedBackgroundView:selectedBackgroundView];
    
    _sharingContainer.alpha = 0;
    self.textToBottomConstraint.constant = - self.separatorHeight;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Accessors

- (void)setMaxTextWidth:(CGFloat)width
{
    self.cellText.preferredMaxLayoutWidth = width - kRightBorderMargin;
}

- (void)setArticle:(Article *)article
{
    _article = article;
    if (article.image.thumbnail) {
        [self.cellImage setImage:[UIImage imageWithData:article.image.thumbnail]];
    } else {
        [self.cellImage setImage:[UIImage imageNamed:@"Pulse-icon"]];
            __weak typeof(self) wSelf = self;
            [self.delegate thumbnailForMedia:self.article.image completion:^(UIImage *image, NSError *error) {
                if (!error && image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(wSelf) sSelf = wSelf;
                        if (sSelf) {
                            [sSelf.cellImage setImage:image];
                        }
                    });
                }
            }];
    }
    self.sharingFavorite.enabled = YES;
    self.cellTitle.text = article.title;
    self.cellText.text = article.annotation;
    self.cellCategory.text = article.category.name;
    self.ratingLabel.text = [NSString stringWithFormat:@"%ld", (long)[article.rating integerValue]];
    self.upButton.enabled = [article.canLike boolValue];
    self.downButton.enabled = [article.canDislike boolValue];
    
    if (self.upButton.enabled && self.downButton.enabled) {
        _likeState = PRLikeStateUnknown;
    } else if (self.upButton.enabled && !self.downButton.enabled) {
        _likeState = PRLikeStateDisliked;
    } else if (!self.upButton.enabled && self.downButton.enabled) {
        _likeState = PRLikeStateLiked;
    }
    [self showShare:NO animated:NO];
    _sharingOpened = NO;
}

#pragma mark - Actions

- (void)clickOnTitle
{
    [self showShare:!_sharingOpened animated:YES];
    _sharingOpened = !_sharingOpened;
}

- (IBAction)shareOnTwitter:(UIButton *)sender
{
    [self.delegate shareTwitter:self.article];
}

- (IBAction)shareOnFacebook:(UIButton *)sender
{
    [self.delegate shareFacebook:self.article];
}

- (IBAction)saveAsFavorite:(UIButton *)sender
{
    self.sharingFavorite.enabled = NO;
    [self.delegate addArticleToFavorite:self.article];
}

- (IBAction)upRating:(UIButton *)sender
{
    if (_likeState == PRLikeStateUnknown) {
        self.upButton.enabled = NO;
        _likeState = PRLikeStateLiked;
    } else if (_likeState == PRLikeStateDisliked) {
        _likeState = PRLikeStateUnknown;
        self.downButton.enabled = YES;
    }
    
    [self.delegate likeArticle:self.article];
    self.ratingLabel.text = [NSString stringWithFormat:@"%ld", (long)[self.article.rating integerValue]];
}

- (IBAction)downRating:(UIButton *)sender
{
    if (_likeState == PRLikeStateUnknown) {
        self.downButton.enabled = NO;
        _likeState = PRLikeStateDisliked;
    } else if (_likeState == PRLikeStateLiked) {
        _likeState = PRLikeStateUnknown;
        self.upButton.enabled = YES;
    }
    
    [self.delegate dislikeArticle:self.article];
    self.ratingLabel.text = [NSString stringWithFormat:@"%ld", (long)[self.article.rating integerValue]];
}


#pragma mark - Internal

- (void)showShare:(BOOL)show animated:(BOOL)animated
{
    self.categoryToShareConstraint.priority = show ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
    self.categoryToTitleConstraint.priority = show ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
    
    self.titleToTopLongConstraint.priority = show ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
    self.titleToTopShortConstraint.priority = show ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
    
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
