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

@implementation PRMenuViewController{
    int _tasksInProcess;
}

static NSString * const kCategoryCellIdentifier = @"menu_category_cell_identifier";
static NSString * const kLocationCellIdentifier = @"menu_location_cell_identifier";
static NSString * const kAddLocationCellIdentifier = @"menu_add_location_cell_identifier";

static NSString * const kToMapSegueIdentifier = @"map_screen_segue_identifier";

static NSString * const kCategoriesSectionTitle = @"Categories";
static NSString * const kLocationsSectionTitle = @"Locations";
static NSString * const kAddLocationLabel = @"Add new location";

#pragma mark - Actions

- (void)refreshing
{
    [self.refreshControll endRefreshing];
}

#pragma mark - PRContentViewDelegate

- (void)viewDidLoad
{
    _tasksInProcess = 0;
    self.refreshControll = [[UIRefreshControl alloc] init];
    [self.refreshControll addTarget:self action:@selector(refreshing) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControll];
}

- (void)menuWillOpen
{
    [self.tableView scrollsToTop];
    self.tableView.userInteractionEnabled = NO;
    [self.refreshControll beginRefreshing];
    __weak typeof(self) wSelf = self;
    [self fetchLocations];
    _tasksInProcess++;
    [self.interactor fetchCategoriesWithCompletion:^(BOOL success, NSString *errorMessage) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (sSelf) {
            if (!success) {
                [sSelf showAlertWithMessage:errorMessage];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                _tasksInProcess--;
                NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
                [indexSet addIndex:0];
                [sSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
                [sSelf unlockView];
            });
        }
    }];
}

- (void)menuDidOpen
{

}

- (void)menuWillClose
{

}

- (void)menuDidClose
{
    __weak typeof(self) wSelf = self;
    [self.interactor saveDataWithCompletion:^(BOOL success, NSString *errorMessage) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (sSelf) {
            if (!success) {
                [sSelf showAlertWithMessage:errorMessage];
            }
        }
    }];
}

#pragma mark - MapInteractorDelegate

- (void)didAddNewLocation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView scrollsToTop];
        self.tableView.userInteractionEnabled = NO;
        [self.refreshControll beginRefreshing];
        [self fetchLocations];
    });
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (indexPath.row) {
        
        } else {
            [self performSegueWithIdentifier:kToMapSegueIdentifier sender:self];
        }
    } else {
        [[self.interactor categoryForIndex:[indexPath row]] setSelected:YES];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section) {
    
    } else {
        [[self.interactor categoryForIndex:[indexPath row]] setSelected:NO];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.interactor removeLocationAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - TableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section) {
        return [self.interactor availableLocations] + 1;
    }
    return [self.interactor availableCategories];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section) {
        if (indexPath.row) {
            PRMenuLocationCell *locationCell = [tableView dequeueReusableCellWithIdentifier:kLocationCellIdentifier];
            if (!locationCell) {
                locationCell = [[PRMenuLocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLocationCellIdentifier];
            }
            locationCell.geoPoint = [self.interactor locationForIndex:indexPath.row];
            cell = locationCell;
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:kAddLocationCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAddLocationCellIdentifier];
            }
            cell.textLabel.text = kAddLocationLabel;
        }
    } else {
        PRMenuCategoryCell *categoryCell = [tableView dequeueReusableCellWithIdentifier:kCategoryCellIdentifier];
        if (!categoryCell) {
            categoryCell = [[PRMenuCategoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCategoryCellIdentifier];
        }
        PRLocalCategory *category = [self.interactor categoryForIndex:[indexPath row]];
        if (category.selected) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        categoryCell.category = category;
        cell = categoryCell;
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section) {
        return kLocationsSectionTitle;
    }
    return kCategoriesSectionTitle;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section &&  indexPath.row) {
        return YES;
    }
    return NO;
}

#pragma mark - Internal

- (void)unlockView
{
    if (_tasksInProcess == 0) {
        [self.refreshControll endRefreshing];
        [self.tableView setUserInteractionEnabled:YES];
    }
}

- (void)fetchLocations
{
    __weak typeof(self) wSelf = self;
    _tasksInProcess++;
    [self.interactor fetchGeoPointsWithCompletion:^(BOOL success, NSString *errorMessage) {
        __strong typeof(wSelf) sSelf = wSelf;
        if (sSelf) {
            if (!success) {
                [sSelf showAlertWithMessage:errorMessage];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                _tasksInProcess--;
                NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
                [indexSet addIndex:1];
                [sSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
                [sSelf unlockView];
            });
        }
    }];
}

@end
