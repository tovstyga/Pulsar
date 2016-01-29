//
//  PRDetailsViewController.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRDetailsViewController.h"
#import "PRImagePresenter.h"
#import "PRDetailsCollectionViewCell.h"

@interface PRDetailsViewController() <PRImagePresenterDataSource>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *articleTitle;
@property (weak, nonatomic) IBOutlet UILabel *annotation;
@property (weak, nonatomic) IBOutlet UILabel *category;
@property (weak, nonatomic) IBOutlet UILabel *rating;
@property (weak, nonatomic) IBOutlet UITextView *mainText;
@property (weak, nonatomic) IBOutlet UICollectionView *megiaCollection;

@property (weak, nonatomic) IBOutlet UIButton *downButton;
@property (weak, nonatomic) IBOutlet UIButton *upButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hideMediaCollectionConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *showMediaCollectionConstraint;

@property (strong, nonatomic) PRImagePresenter *imagePresenter;

@end

@implementation PRDetailsViewController{
    NSInteger _selectedImageIndex;
}

static NSString * const kDetailsMediaCellIdentifier = @"details_media_cell_identifier";

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self showMediaCollection:NO animated:NO];
    _selectedImageIndex = -1;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.article.image.thumbnail) {
        self.imageView.image = self.article.image.thumbnail;
    } else {
        [self.interactor loadImageFromUrl:self.article.image.thumbnailUrl completion:^(UIImage *image, NSString *errorMessage) {
            if (!errorMessage) {
                self.article.image.thumbnail = image;
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = image;
                });
            }
        }];
    }
    self.articleTitle.text = self.article.title;
    self.annotation.text = self.article.annotation;
    self.category.text = self.article.category.title;
    self.rating.text = [NSString stringWithFormat:@"%ld", (long)self.article.rating];
    self.mainText.text = self.article.text;
    
    [self.interactor loadMediaContentForArticle:self.article completion:^(NSString *errorMessage) {
        if (!errorMessage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.megiaCollection reloadData];
                if ([self.interactor mediaContentCount]) {
                    [self showMediaCollection:YES animated:YES];
                }
            });
        }
    }];
}

#pragma mark - Actions

- (IBAction)cancelAction:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clickOnImage:(UITapGestureRecognizer *)sender
{
    if (self.article.image.imageUrl) {
        [self showImage];
    }
}

- (IBAction)upRationgAction:(UIButton *)sender
{

}

- (IBAction)downRatingAction:(UIButton *)sender
{

}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.interactor mediaContentCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PRDetailsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kDetailsMediaCellIdentifier forIndexPath:indexPath];
    [[cell image] setImage:[self.interactor thumbnailForItemAtIndex:indexPath.item]];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedImageIndex = indexPath.row;
    [self showImage];
    _selectedImageIndex = -1;
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

#pragma mark - PRImagePresenterDataSource

- (void)loadImageWithCompletion:(void(^)(UIImage *image, NSString *errorMessage))completion
{
    if (_selectedImageIndex >= 0) {
        [self.interactor imageForItemAtIndex:_selectedImageIndex completion:^(UIImage *image, NSString *errorMessage) {
            completion(image, errorMessage);
        }];
    } else {
        if (self.article.image.image) {
            completion(self.article.image.image, nil);
        } else {
            [self.interactor loadImageFromUrl:self.article.image.imageUrl completion:^(UIImage *image, NSString *errorMessage) {
                self.article.image.image = image;
                completion(image, errorMessage);
            }];
        }
    }
}

#pragma mark - Internal

- (void)showImage
{
    if (!self.imagePresenter) {
        self.imagePresenter = [[PRImagePresenter alloc] init];
        self.imagePresenter.dataSource = self;
    }
    [self.imagePresenter presentFromParentViewController:self animated:YES completion:nil];
}

- (void)showMediaCollection:(BOOL)show animated:(BOOL)animated
{
    self.showMediaCollectionConstraint.priority = show ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
    self.hideMediaCollectionConstraint.priority = show ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
    if (animated) {
        if (show) {
            [UIView animateWithDuration:0.3f animations:^{
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3f animations:^{
                    self.megiaCollection.alpha = 1;
                }];
            }];
        } else {
            [UIView animateWithDuration:0.3f animations:^{
                self.megiaCollection.alpha = 0;
                [self.view layoutIfNeeded];
            }];
        }
    } else {
        [self.view layoutIfNeeded];
        self.megiaCollection.alpha = show ? 1 : 0;
    }
    
}

@end
