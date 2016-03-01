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
#import "InterestCategory.h"
#import "PRLocationManager.h"

@interface PRMenuViewController()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIRefreshControl *refreshControll;
@property (weak, nonatomic) IBOutlet UIImageView *menuBackground;

@end

@implementation PRMenuViewController{
    int _tasksInProcess;
    NSIndexPath *_selectedLocation;
}

static NSString * const kCategoryCellIdentifier = @"menu_category_cell_identifier";
static NSString * const kLocationCellIdentifier = @"menu_location_cell_identifier";
static NSString * const kAddLocationCellIdentifier = @"menu_add_location_cell_identifier";
static NSString * const kBasicCellIdentifier = @"menu_basic_cell_identifier";

static NSString * const kToMapSegueIdentifier = @"map_screen_segue_identifier";

static NSString * const kSystemOptions = @"System Options";
static NSString * const kCategoriesSectionTitle = @"Categories";
static NSString * const kLocationsSectionTitle = @"Locations";
static NSString * const kAddLocationLabel = @"Add new location";
static NSString * const kCurrentLocationLabel = @"Current location";
static NSString * const kLogoutLabel = @"Logout";
static NSString * const kLogoutImageName = @"export-50";

@dynamic interactor;

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
    [self.refreshControll setTintColor:[UIColor whiteColor]];
    [self.refreshControll addTarget:self action:@selector(refreshing) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControll];
    [self addShadowAndCornerToView:self.menuBackground];
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
    [self updateShadowPathForView:self.menuBackground];
    self.menuBackground.layer.shadowColor = [UIColor blackColor].CGColor;
}

- (void)menuWillClose
{
    [self updateShadowPathForView:self.menuBackground];
    self.menuBackground.layer.shadowColor = [UIColor clearColor].CGColor;
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
    if (indexPath.section == 1) {
        if (indexPath.row) {
            if (_selectedLocation.row != indexPath.row) {
                if (_selectedLocation) {
                    [tableView deselectRowAtIndexPath:_selectedLocation animated:YES];
                }
                NSIndexPath *oldPath = _selectedLocation;
                _selectedLocation = indexPath;
                NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
                [indexSet addIndex:1];
                
                [tableView reloadRowsAtIndexPaths:@[oldPath, indexPath] withRowAnimation:UITableViewRowAnimationNone];
                
                if (indexPath.row == 1) {
                    [PRLocationManager sharedInstance].selectedCoordinate = [PRLocationManager sharedInstance].currentLocation.coordinate;
                } else {
                    PRLocalGeoPoint *point = [self.interactor locationForIndex:indexPath.row - 2];
                    [PRLocationManager sharedInstance].selectedCoordinate = CLLocationCoordinate2DMake(point.latitude, point.longitude);
                }
            }
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            [self performSegueWithIdentifier:kToMapSegueIdentifier sender:self];
        }
    } else if (indexPath.section == 2) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.interactor logout];
    } else {
        [[self.interactor categoryForIndex:[indexPath row]] setSelected:@(YES)];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section) {

    } else {
        [[self.interactor categoryForIndex:[indexPath row]] setSelected:@(NO)];
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
    if (section == 1) {
        return [self.interactor availableLocations] + 2;
    } else if (section == 2) {
        return 1;
    }
    return [self.interactor availableCategories];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == 1) {
        if (indexPath.row > 1) {
            PRMenuLocationCell *locationCell = [tableView dequeueReusableCellWithIdentifier:kLocationCellIdentifier];
            if (!locationCell) {
                locationCell = [[PRMenuLocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLocationCellIdentifier];
            }
            locationCell.geoPoint = [self.interactor locationForIndex:indexPath.row - 2];
            if (_selectedLocation.row == indexPath.row) {
                [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

            }
            cell = locationCell;
        } else if (indexPath.row) {
            PRMenuLocationCell *locationCell = [tableView dequeueReusableCellWithIdentifier:kLocationCellIdentifier];
            if (!locationCell) {
                locationCell = [[PRMenuLocationCell alloc]  initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAddLocationCellIdentifier];
            }
            locationCell.textLabel.text = kCurrentLocationLabel;
            if (!_selectedLocation || indexPath.row == _selectedLocation.row) {
                _selectedLocation = indexPath;
                [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
            cell = locationCell;
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:kAddLocationCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kAddLocationCellIdentifier];
            }
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = kAddLocationLabel;
        }
    } else if (indexPath.section == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:kBasicCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kBasicCellIdentifier];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = kLogoutLabel;
        cell.imageView.image = [UIImage imageNamed:kLogoutImageName];
    } else {
        PRMenuCategoryCell *categoryCell = [tableView dequeueReusableCellWithIdentifier:kCategoryCellIdentifier];
        if (!categoryCell) {
            categoryCell = [[PRMenuCategoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCategoryCellIdentifier];
        }
        InterestCategory *category = [self.interactor categoryForIndex:[indexPath row]];
        if ([category.selected boolValue]) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        categoryCell.category = category;
        cell = categoryCell;
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return kLocationsSectionTitle;
    } else if (section == 2) {
        return kSystemOptions;
    }
    return kCategoriesSectionTitle;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section && indexPath.row == 1) {
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

- (void)addShadowAndCornerToView:(UIView *)view
{
    view.layer.shadowColor = [UIColor clearColor].CGColor;
    view.layer.masksToBounds = NO;
    view.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
    view.layer.shadowOpacity = 0.5f;
    view.layer.shadowRadius = 5.0f;
    [self updateShadowPathForView:view];
}

- (void)updateShadowPathForView:(UIView *)view
{
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:view.layer.bounds];
    view.layer.shadowPath = shadowPath.CGPath;
}

@end
