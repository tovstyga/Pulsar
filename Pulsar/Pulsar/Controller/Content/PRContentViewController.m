//
//  PRContentViewController.m
//  Pulsar
//
//  Created by fantom on 12.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRContentViewController.h"
#import "PRScreenLock.h"

@interface PRContentViewController()<UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuTabBarButton;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;

@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemHot;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemNew;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemTop;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemFavorites;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabItemCreated;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabBarConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBarConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoriesMenuConstraint;

@end

@implementation PRContentViewController{
    BOOL _isOpenedMenu;
    BOOL _lockOpenMenuInteraction;
    CGFloat _closedMenuDefaultConstraint;
}

static CGFloat const kSpaceFromMenuToRightBorder = 40;
static NSString * const kToContentSegueIdentifier = @"content_to_login_segue";

#pragma mark - Life

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tabBar setDelegate:self];
    [self.tabBar setSelectedItem:self.tabItemTop];
    
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
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark - Events

- (IBAction)toggleFilters:(UIBarButtonItem *)sender
{
    [self toggleMenu];
}

- (IBAction)refresh:(UIBarButtonItem *)sender
{
    [self.interactor reloadDataWithCompletion:^(BOOL success, NSString *errorMessage) {
        
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
    [self.interactor reloadDataWithCompletion:^(BOOL success, NSString *errorMessage) {
        [[PRScreenLock sharedInstance] unlockAnimated:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            _lockOpenMenuInteraction = NO;
            self.menuTabBarButton.enabled = YES;
        });
    }];
}

#pragma mark - Internal

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
    [UIView animateWithDuration:1.f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.categoriesMenuConstraint.constant = hide ? _closedMenuDefaultConstraint : kSpaceFromMenuToRightBorder;
        [self.view setNeedsLayout];
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
