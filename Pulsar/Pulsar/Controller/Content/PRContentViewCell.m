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
@property (weak, nonatomic) IBOutlet UIImageView *backgroundCell;
@property (weak, nonatomic) IBOutlet UIButton *rotatedButton;

@property (weak, nonatomic) IBOutlet UIButton *sharingTwitter;
@property (weak, nonatomic) IBOutlet UIButton *sharingFacebook;
@property (weak, nonatomic) IBOutlet UIButton *sharingFavorite;

@property (weak, nonatomic) IBOutlet UIButton *upButton;
@property (weak, nonatomic) IBOutlet UIButton *downButton;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;

@property (weak, nonatomic) IBOutlet UIStackView *extendedContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textToBottomConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentToImageShort;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentToImageLong;

@end

@implementation PRContentViewCell{
    BOOL _animationInProcess;
    BOOL _expanded;
    PRLikeState _likeState;
    CGRect _currentDrowRect;
}

static int const kRightBorderMargin = 70;

- (void)awakeFromNib {
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOnTitle)];
    [self.cellTitle addGestureRecognizer:tapRecognizer];
    
    UIView *selectedBackgroundView = [[UIView alloc] init];
    [selectedBackgroundView setBackgroundColor:[UIColor clearColor]];
    [self setSelectedBackgroundView:selectedBackgroundView];
    
    _expandedDelta = self.contentToImageLong.constant - self.contentToImageShort.constant;
    
    self.backgroundCell.layer.masksToBounds = YES;
    self.backgroundCell.layer.cornerRadius = 5.f;
    
    self.extendedContainer.alpha = _expanded ? 1 : 0;
    self.textToBottomConstraint.constant = - self.separatorHeight;
    
    self.cellText.layer.masksToBounds = NO;
    
    [self layoutIfNeeded];
}

- (void)drawRect:(CGRect)rect
{
    _currentDrowRect = rect;
    if (!_animationInProcess) {
        self.backgroundCell.frame = CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect) - self.separatorHeight);
    }
    [super drawRect:rect];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    self.contentToImageLong.priority = UILayoutPriorityDefaultLow;
    self.contentToImageShort.priority = UILayoutPriorityDefaultHigh;
    self.extendedContainer.alpha = 0;
    self.rotatedButton.transform = CGAffineTransformMakeRotation(0);
    _expanded = NO;
    [self setNeedsDisplay];
    [super prepareForReuse];
}


#pragma mark - Accessors

- (void)expandeCell
{
    if (_expanded) {
        return;
    }
    _expanded = YES;
    [self expandeCell:_expanded callDelegate:NO];
}

- (void)colapseCell
{
    if (!_expanded) {
        return;
    }
    _expanded = NO;
    [self expandeCell:_expanded callDelegate:NO];
}

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

}

#pragma mark - Actions

- (void)clickOnTitle
{
    _expanded = !_expanded;
    [self expandeCell:_expanded callDelegate:YES];
}
- (IBAction)expandeCell:(id)sender
{
    [self clickOnTitle];
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

- (void)expandeCell:(BOOL)expande callDelegate:(BOOL)call
{
    self.contentToImageLong.priority = expande ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
    self.contentToImageShort.priority = expande ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(expande ? M_PI : 0);
    
        if (expande) {
            if (call) [self.delegate willExpandCell:self];
            _animationInProcess = YES;
            [UIView animateWithDuration:0.3f animations:^{
                [self.rotatedButton setTransform:transform];
                [self layoutIfNeeded];
                if (call) [self.delegate didExpandCell:self];
            } completion:^(BOOL finished) {
                _animationInProcess = NO;
                self.backgroundCell.frame = CGRectMake(CGRectGetMinX(_currentDrowRect), CGRectGetMinY(_currentDrowRect), CGRectGetWidth(_currentDrowRect), CGRectGetHeight(_currentDrowRect) - self.separatorHeight);
//                if (call) [self.delegate didExpandCell:self];
                [UIView animateWithDuration:0.3f animations:^{
                    self.extendedContainer.alpha = 1;
                }];
            }];
        } else {
            if (call) [self.delegate willCollapseCell:self];
            _animationInProcess = YES;
            [UIView animateWithDuration:0.3f animations:^{
                [self.rotatedButton setTransform:transform];
                self.extendedContainer.alpha = 0;
                [self layoutIfNeeded];
                if (call) [self.delegate didCollapseCell:self];
            } completion:^(BOOL finished) {
                _animationInProcess = NO;
                self.backgroundCell.frame = CGRectMake(CGRectGetMinX(_currentDrowRect), CGRectGetMinY(_currentDrowRect), CGRectGetWidth(_currentDrowRect), CGRectGetHeight(_currentDrowRect) - self.separatorHeight);
//                if (call) [self.delegate didCollapseCell:self];
            }];
        }
}

@end
