//
//  PRContentViewController.m
//  Pulsar
//
//  Created by fantom on 12.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRContentViewController.h"
#import "PRScreenLock.h"
#import "PRContentViewCell.h"
#import "PRDetailsViewController.h"
#import "PRSocialHelper.h"
#import "PRMacros.h"

@interface PRContentViewController()<UITabBarDelegate, PRContentCellDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuTabBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *logoutButton;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemHot;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemNew;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemTop;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemFavorites;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemCreated;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabBarConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoriesMenuConstraint;
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

@property (strong, nonatomic) UIRefreshControl *refreshControll;

@end

@implementation PRContentViewController{
    BOOL _isOpenedMenu;
    BOOL _lockOpenMenuInteraction;

    CGFloat _closedMenuDefaultConstraint;
    NSIndexPath *_selectedItem;
    
    PRContentViewCell *_expandedCell;
    NSIndexPath *_expandedIndexPath;
    
    BOOL _loadingInProcess;
    dispatch_once_t once;
}

static CGFloat const kNavigationBarHeight = 64;
static CGFloat const kToolBarHeight = 50;
static CGFloat const kSpaceFromMenuToRightBorder = 40;
static NSString * const kToLoginSegueIdentifier = @"content_to_login_segue";

static NSString * const kContentCellIdentifier = @"content_cell_identifier";

@dynamic interactor;

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if ([segue.destinationViewController isKindOfClass:[PRDetailsViewController class]]) {
        [(PRDetailsViewController *)segue.destinationViewController setArticle:[self.interactor articleAtIndex:_selectedItem.row inSection:_selectedItem.section]];
    }
}

#pragma mark - Life

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect bounds = self.tabBar.bounds;
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    visualEffectView.frame = bounds;
    visualEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:visualEffectView belowSubview:self.tabBar];
    self.tabBar.backgroundColor = [UIColor clearColor];
    
    [self.contentTableView setContentInset:UIEdgeInsetsMake(0, 0, kToolBarHeight, 0)];
    
    [self.tabBar setDelegate:self];
    [self.tabBar setSelectedItem:self.tabItemTop];
    [self.interactor setActiveFeed:PRFeedTypeTop];
    
    self.refreshControll = [[UIRefreshControl alloc] init];
    [self.refreshControll setTintColor:[UIColor whiteColor]];
    [self.refreshControll addTarget:self action:@selector(refreshing) forControlEvents:UIControlEventValueChanged];
    [self.contentTableView addSubview:self.refreshControll];
    self.contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    _closedMenuDefaultConstraint = self.view.frame.size.width;
    _isOpenedMenu = NO;
    [self.categoriesMenuConstraint setConstant:_closedMenuDefaultConstraint];
    [self.view setNeedsLayout];
    if (_isOpenedMenu) {
        [self toggleMenu];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.interactor isLogined]) {
        dispatch_once(&once, ^{
            [self refresh:nil];
        });
    } else {
        [self performSegueWithIdentifier:kToLoginSegueIdentifier sender:self];
    }
}

#pragma mark - Events

- (void)refreshing
{
    [self refresh:nil];
}

- (IBAction)toggleFilters:(UIBarButtonItem *)sender
{
    [self toggleMenu];
}

- (IBAction)refresh:(UIBarButtonItem *)sender
{
    _expandedIndexPath = nil;
    _expandedCell = nil;	
    
    _loadingInProcess = YES;
    [self showRefreshControll:YES];
    [self.contentTableView scrollsToTop];
    [self.refreshButton setEnabled:NO];
    self.contentTableView.userInteractionEnabled = NO;
    [self.interactor reloadDataWithCompletion:^(BOOL success, NSString *errorMessage) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.contentTableView reloadData];
                [self showRefreshControll:NO];
                self.contentTableView.userInteractionEnabled = YES;
                self.refreshButton.enabled = YES;
                _loadingInProcess = NO;
            });
        }
    }];
}

- (IBAction)logout:(UIBarButtonItem *)sender
{
    [[PRScreenLock sharedInstance] lockView:self.view];
    __weak typeof(self) wSelf = self;
    [self.interactor logoutWithCompletion:^(BOOL success, NSString *errorMessage) {
        __strong typeof(wSelf) sSelf = wSelf;
        [[PRScreenLock sharedInstance] unlock];
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                once++;
                [sSelf performSegueWithIdentifier:kToLoginSegueIdentifier sender:sSelf];
            });
        } else {
            [sSelf showAlertWithMessage:errorMessage];
        }
    }];
}

- (IBAction)swipeFromEdge:(UIScreenEdgePanGestureRecognizer *)sender
{
    if (!_isOpenedMenu) {
        [self toggleMenu];
    }
}

- (IBAction)swipe:(UISwipeGestureRecognizer *)sender
{
    if (_isOpenedMenu) {
        [self toggleMenu];
    }
}

#pragma mark - TabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    _expandedIndexPath = nil;
    _expandedCell = nil;
    if (_isOpenedMenu) {
        [self hideMenu:YES];
    }
    NSString *title = @"News";
    if (item == self.tabItemHot) {
        self.interactor.activeFeed = PRFeedTypeHot;
        title = item.title;
    } else if (item == self.tabItemNew) {
        self.interactor.activeFeed = PRFeedTypeNew;
        title = item.title;
    } else if (item == self.tabItemTop) {
        self.interactor.activeFeed = PRFeedTypeTop;
        title = @"Most Viewed";
    } else if (item == self.tabItemFavorites) {
        self.interactor.activeFeed = PRFeedTypeFavorites;
        title = @"Favorites";
    } else if (item == self.tabItemCreated) {
        self.interactor.activeFeed = PRFeedTypeCreated;
        title = item.title;
    }
    self.navigationController.navigationBar.topItem.title  = title;
    if ([self isDataAvailable]) {
        [self.contentTableView reloadData];
    } else {
        [self refresh:nil];
    }
}

#pragma mark - MenuInteractorDelegate

- (void)willUpdateUserSettings
{
    _lockOpenMenuInteraction = YES;
    self.menuTabBarButton.enabled = NO;
    [[PRScreenLock sharedInstance] lockView:self.view animated:YES];
}

- (void)didUpdateUserSettings
{
//    [self.interactor reloadDataWithCompletion:^(BOOL success, NSString *errorMessage)
        dispatch_async(dispatch_get_main_queue(), ^{
            [[PRScreenLock sharedInstance] unlockAnimated:YES];
            _lockOpenMenuInteraction = NO;
            self.menuTabBarButton.enabled = YES;
        });
//    }];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.interactor titleForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self.interactor numberOfSections] < 2) {
        return [[UIView alloc] initWithFrame:CGRectZero];
    }
    CGRect headerRect = CGRectMake(tableView.separatorInset.left, 0, tableView.bounds.size.width - tableView.separatorInset.left - tableView.separatorInset.right, 30);
    CGRect bgRect = CGRectMake(CGRectGetMinX(headerRect),
                               CGRectGetMinY(headerRect),
                               CGRectGetWidth(headerRect),
                               CGRectGetHeight(headerRect) - 2);
    CGFloat labelMargin = 6;
    CGRect labelRect = CGRectMake(CGRectGetMinX(headerRect) + labelMargin,
                                  CGRectGetMinY(headerRect) + labelMargin,
                                  CGRectGetWidth(headerRect) - labelMargin * 2,
                                  CGRectGetHeight(headerRect) - labelMargin * 2);
    
    UIImageView *bgView = [[UIImageView alloc] initWithFrame:bgRect];
    [bgView setImage:[UIImage imageNamed:@"bg-cell-article"]];
    
    UILabel *title = [[UILabel alloc] initWithFrame:labelRect];
    title.text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    
    UIView *header = [[UIView alloc] initWithFrame:headerRect];
    [header addSubview:bgView];
    [header addSubview:title];
    header.backgroundColor = UIColorFromRGBWithAlpha(0x000000, 0.8);
    
    return header;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.interactor numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.interactor numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kContentCellIdentifier];
    if (!cell) {
        cell = [[PRContentViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kContentCellIdentifier];
        [(PRContentViewCell *)cell setDelegate:self];
    }
    [self setupCell:(PRContentViewCell *)cell atIndexPath:indexPath];
    return cell;
}

- (void)setupCell:(PRContentViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell setDelegate:self];
    [cell setArticle:[self.interactor articleAtIndex:indexPath.row inSection:indexPath.section]];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_expandedIndexPath isEqual:indexPath]) {
        [(PRContentViewCell *)cell expandeCell];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedItem = indexPath;
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = -1000;
    if ((y > h + reload_distance) && (!_loadingInProcess) && [self.interactor canLoadMore] && [self isDataAvailable]) {
        _loadingInProcess = YES;
        [self.interactor loadNewDataWithCompletion:^(BOOL success, NSString *errorMessage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _loadingInProcess = NO;
                if (success) {
                    [self.contentTableView reloadData];
                }
            });
        }];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static PRContentViewCell *cell;
    if (!cell) {
        cell = [self.contentTableView dequeueReusableCellWithIdentifier:kContentCellIdentifier];
        [cell setMaxTextWidth:CGRectGetWidth(self.contentTableView.frame)];
    }
    [self setupCell:cell atIndexPath:indexPath];
    
    CGFloat size = [self calculateHeightForConfiguredSizingCell:cell];
    
    if ([indexPath isEqual:_expandedIndexPath]) {
        size += cell.expandedDelta;
    }
    
    return size;
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell {
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

#pragma merk - PRContentCellDelegate

- (void)shareTwitter:(Article *)article
{
    [PRSocialHelper showTwitterShareDialogForArticle:article fromViewController:self];
}

- (void)shareFacebook:(Article *)article
{
    [PRSocialHelper showFacebookShareDialogForArticle:article fromViewController:self];
}

- (void)likeArticle:(Article *)article
{
    [self.interactor likeArticle:article completion:nil];
}

- (void)dislikeArticle:(Article *)article
{
    [self.interactor dislikeArticle:article completion:nil];
}

- (void)thumbnailForMedia:(Media *)media completion:(void(^)(UIImage *image, NSError *error))completion
{
    [self.interactor thumbnailForMedia:media completion:completion];
}

- (void)addArticleToFavorite:(Article *)article
{
    [self.interactor addArticleToFavorite:article];
}

- (void)willExpandCell:(PRContentViewCell *)cell
{
    if (_expandedCell) {
        [_expandedCell colapseCell];
    }
    _expandedCell = cell;
    _expandedIndexPath = [self.contentTableView indexPathForCell:cell];
    [self.contentTableView beginUpdates];
}

- (void)didExpandCell:(PRContentViewCell *)cell
{
    [self.contentTableView endUpdates];
}

- (void)willCollapseCell:(PRContentViewCell *)cell
{
    _expandedCell = nil;
    _expandedIndexPath = nil;
    [self.contentTableView beginUpdates];
}

- (void)didCollapseCell:(PRContentViewCell *)cell
{
    [self.contentTableView endUpdates];
}

#pragma mark - Internal

- (BOOL)isDataAvailable
{
    return [self.interactor isDataAvailable];
}

- (void)showRefreshControll:(BOOL)show
{
    if (show) {
        [self.refreshControll beginRefreshing];
        [self.contentTableView setContentOffset:CGPointMake(0, -kNavigationBarHeight -self.refreshControll.frame.size.height) animated:YES];
    } else {
        [self.refreshControll endRefreshing];
        [self.contentTableView setContentOffset:CGPointMake(0, -kNavigationBarHeight) animated:YES];
    }
}

- (void)toggleMenu
{
    if (!_lockOpenMenuInteraction) {
        [self hideMenu:_isOpenedMenu];
    }
}

- (void)hideMenu:(BOOL)hide
{
    if (hide) {
        if ([self.delegate respondsToSelector:@selector(menuWillClose)]) {
            [self.delegate menuWillClose];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(menuWillOpen)]) {
            [self.delegate menuWillOpen];
        }
    }
    
    self.refreshButton.enabled = hide ? YES : NO;
    self.logoutButton.enabled = hide ? YES : NO;
    self.addButton.enabled = hide ? YES : NO;
    self.contentTableView.userInteractionEnabled = hide ? YES : NO;
    
    
    _isOpenedMenu = !hide;
    self.categoriesMenuConstraint.constant = hide ? _closedMenuDefaultConstraint : kSpaceFromMenuToRightBorder;
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (hide) {
            if ([self.delegate respondsToSelector:@selector(menuDidClose)]) {
                [self.delegate menuDidClose];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(menuDidOpen)]) {
                [self.delegate menuDidOpen];
            }
        }
    }];
}


@end
