//
//  PRMenuViewController.m
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRMenuViewController.h"
#import "PRMenuCategoryCell.h"
#import "PRMenuLocationCell.h"
#import "PRLocalCategory.h"

@interface PRMenuViewController()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIRefreshControl *refreshControll;

@end

@implementation PRMenuViewController

static NSString * const kCategoryCellIdentifier = @"menu_category_cell_identifier";
static NSString * const kLocationCellIdentifier = @"menu_location_cell_identifier";

#pragma mark - Actions

- (void)refreshing
{
    [self.refreshControll endRefreshing];
}

#pragma mark - PRContentViewDelegate

- (void)viewDidLoad
{
    self.refreshControll = [[UIRefreshControl alloc] init];
    [self.refreshControll addTarget:self action:@selector(refreshing) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControll];
}

- (void)menuWillOpen
{
    self.tableView.userInteractionEnabled = NO;
    [self.refreshControll beginRefreshing];
    __weak typeof(self) wSelf = self;
    [self.interactor fetchDataWithCompletion:^(BOOL success, NSString *errorMessage) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (sSelf) {
            if (!success) {
                [sSelf showAlertWithMessage:errorMessage];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [sSelf.refreshControll endRefreshing];
                [sSelf.tableView reloadData];
                [sSelf.tableView setUserInteractionEnabled:YES];
            });
        }
    }];
}

- (void)menuDidOpen
{

}

- (void)menuWillClose
{
    [self.interactor saveDataWithCompletion:^(BOOL success, NSString *errorMessage) {
        
    }];
}

- (void)menuDidClose
{

}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[self.interactor categoryForIndex:[indexPath row]] setSelected:YES];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[self.interactor categoryForIndex:[indexPath row]] setSelected:NO];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - TableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.interactor availableCategories];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PRMenuCategoryCell *categoryCell = [tableView dequeueReusableCellWithIdentifier:kCategoryCellIdentifier];
    if (!categoryCell) {
        categoryCell = [[PRMenuCategoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCategoryCellIdentifier];
    }
    PRLocalCategory *category = [self.interactor categoryForIndex:[indexPath row]];
    if (category.selected) {
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    categoryCell.category = category;
    return categoryCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

@end
