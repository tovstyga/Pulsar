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

@interface PRContentViewController()<UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuTabBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemHot;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemNew;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemTop;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemFavorites;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemCreated;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabBarConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBarConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoriesMenuConstraint;
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

@property (strong, nonatomic) UIRefreshControl *refreshControll;

@end

@implementation PRContentViewController{
    BOOL _isOpenedMenu;
    BOOL _lockOpenMenuInteraction;

    CGFloat _closedMenuDefaultConstraint;
    NSIndexPath *_selectedItem;
    
    BOOL _loadingInProcess;
}

static CGFloat const kSpaceFromMenuToRightBorder = 40;
static NSString * const kToContentSegueIdentifier = @"content_to_login_segue";

static NSString * const kContentCellIdentifier = @"content_cell_identifier";

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
    
    [self.tabBar setDelegate:self];
    [self.tabBar setSelectedItem:self.tabItemTop];
    [self.interactor setActiveFeed:PRFeedTypeTop];
    
    self.refreshControll = [[UIRefreshControl alloc] init];
    [self.refreshControll addTarget:self action:@selector(refreshing) forControlEvents:UIControlEventValueChanged];
    [self.contentTableView addSubview:self.refreshControll];
    
    _closedMenuDefaultConstraint = self.view.frame.size.width;
    _isOpenedMenu = NO;
    [self.categoriesMenuConstraint setConstant:_closedMenuDefaultConstraint];
    [self.view setNeedsLayout];
    if (_isOpenedMenu) {
        [self toggleMenu];
    }
    
    [self refresh:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
                [sSelf performSegueWithIdentifier:kToContentSegueIdentifier sender:sSelf];
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
    if (_isOpenedMenu) {
        [self hideMenu:YES];
    }
    if (item == self.tabItemHot) {
        self.interactor.activeFeed = PRFeedTypeHot;
    } else if (item == self.tabItemNew) {
        self.interactor.activeFeed = PRFeedTypeNew;
    } else if (item == self.tabItemTop) {
        self.interactor.activeFeed = PRFeedTypeTop;
    } else if (item == self.tabItemFavorites) {
        self.interactor.activeFeed = PRFeedTypeFavorites;
    } else if (item == self.tabItemCreated) {
        self.interactor.activeFeed = PRFeedTypeCreated;
    }
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
    }
    [(PRContentViewCell *)cell setArticle:[self.interactor articleAtIndex:indexPath.row inSection:indexPath.section]];
    return cell;
}

#pragma mark - UITableViewDelegate

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

#pragma mark - Internal

- (BOOL)isDataAvailable
{
    return [self.interactor isDataAvailable];
}

- (void)showRefreshControll:(BOOL)show
{
    if (show) {
        [self.refreshControll beginRefreshing];
        [self.contentTableView setContentOffset:CGPointMake(0, -self.refreshControll.frame.size.height) animated:YES];
    } else {
        [self.refreshControll endRefreshing];
        [self.contentTableView setContentOffset:CGPointMake(0, 0) animated:YES];
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
