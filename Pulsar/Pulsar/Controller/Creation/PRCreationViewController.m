//
//  PRCreationViewController.m
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRCreationViewController.h"
#import "PRCreationCollectionViewCell.h"
#import "PRPickerViewPresenter.h"
#import "PRScreenLock.h"

@interface PRCreationViewController()

@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextView *annotationTextView;
@property (weak, nonatomic) IBOutlet UITextView *mainTextView;
@property (weak, nonatomic) UITextView *activeTextView;

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *categoryButton;

@property (weak, nonatomic) IBOutlet UICollectionView *galletyCollectionView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapOnMainViewRecognizer;

@property (nonatomic) CGFloat currentOffset;

@end

@implementation PRCreationViewController {
    NSMutableArray *_images;
    BOOL _gallerySelection;
    NSInteger _selectedCategory;
    NSInteger _acceptedCategory;
}

static NSString * const kAddImageCellIdentifier = @"add_image_cell_identifier";
static NSString * const kGalleryCellIdentifier = @"callery_cell_identifier";

static int const kHeightFromKeyboard = 10;

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    _images = [NSMutableArray new];
    UITapGestureRecognizer *tapOnImageRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectImageAction)];
    tapOnImageRecognizer.numberOfTapsRequired = 1;
    [self.imageView setUserInteractionEnabled:YES];
    [self.imageView addGestureRecognizer:tapOnImageRecognizer];
    _acceptedCategory = -1;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    self.currentOffset = 0;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Accessors

- (UIImagePickerController *)imagePickerController
{
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    return _imagePickerController;
}

- (void)setCurrentOffset:(CGFloat)currentOffset
{
    if (currentOffset != _currentOffset) {
        [self moveViewTo:currentOffset];
        _currentOffset = currentOffset;
    }
}

#pragma mark - Actions

- (IBAction)cancelAction:(UIBarButtonItem *)sender
{
    [_images removeAllObjects];
    self.imageView.image = nil;
    [self.galletyCollectionView reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)publishAction:(UIBarButtonItem *)sender
{
    [self hideKeyboard];
    __weak typeof(self) wSelf = self;
    if ([self.titleTextField.text length] && [self.mainTextView.text length] && _acceptedCategory >= 0) {
        [[PRScreenLock sharedInstance] lockView:self.view animated:YES];
        [self.interactor publishNewArticleWithTitle:self.titleTextField.text
                                         annotation:self.annotationTextView.text
                                               text:self.mainTextView.text
                                           gategory:[[self.interactor allAvailableCategoriesNames] objectAtIndex:_acceptedCategory]
                                              image:self.imageView.image
                                             images:_images completion:^(BOOL success, NSString *errorMessage) {
                                                 [[PRScreenLock sharedInstance] unlockAnimated:YES];
                                                 __strong typeof(wSelf) sSelf = wSelf;
                                                 if (sSelf) {
                                                     if (!success) {
                                                         [sSelf showAlertWithMessage:errorMessage];
                                                     }
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         [sSelf cancelAction:nil];
                                                     });
                                                 }
                                             }];
    } else {
        [self showAlertWithMessage:@"For publishing articles needs title, article and category. Please cheack items state."];
    }
}

- (IBAction)selectCategoryAction:(UIButton *)sender
{
    [self hideKeyboard];
    __block NSArray *categories = [self.interactor allAvailableCategoriesNames];
    
    __weak typeof(self) wSelf = self;
    void(^actionBlock)() = ^(){
        __strong typeof(wSelf) sSelf = wSelf;
        if (sSelf) {
        [[PRPickerViewPresenter sharedInstance] presentActionSheetInView:sSelf.view contentData:categories selectedItem:_selectedCategory completion:^(BOOL accept, NSInteger lastSelectedIndex) {
            _selectedCategory = lastSelectedIndex;
            if (accept) {
                __strong typeof(wSelf) sSelf2 = wSelf;
                if (sSelf2) {
                    [sSelf2.categoryButton setTitle:categories[lastSelectedIndex] forState:UIControlStateNormal];
                    _acceptedCategory = lastSelectedIndex;
                }
            }
        }];
        }
    };
    
    if ([categories count] == 0) {
        [[PRScreenLock sharedInstance] lockView:self.view animated:YES];
        [self.interactor loadCategoriesWithCompletion:^(BOOL success, NSString *errorMessage) {
            __strong typeof(wSelf) sSelf = wSelf;
            if (!success && sSelf) {
                
                [sSelf showAlertWithMessage:errorMessage];
            } else if (sSelf) {
                categories = [sSelf.interactor allAvailableCategoriesNames];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[PRScreenLock sharedInstance] unlockAnimated:YES];
                    actionBlock();
                });
            }
        }];
        
    } else {
        actionBlock();
    }
}

- (void)selectImageAction
{
    [self hideKeyboard];
    _gallerySelection = NO;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)tapOnView:(UITapGestureRecognizer *)sender
{
    [self hideKeyboard];
}

#pragma mark - Events

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    [self.tapOnMainViewRecognizer setEnabled:YES];
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    if (self.activeTextView) {
        self.currentOffset = [self pointsToShowView:self.activeTextView behiedKeyboardWithHeight:kbSize.height];
    } else if (self.currentOffset) {
        self.currentOffset = 0;
    }
}

#pragma mark - CollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_images count] + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = indexPath.item ? kGalleryCellIdentifier : kAddImageCellIdentifier;
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (indexPath.item) {
        [[(PRCreationCollectionViewCell *)cell imageView] setImage:_images[indexPath.item - 1]];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    if (indexPath.item) {
        [_images removeObjectAtIndex:indexPath.item - 1];
        [collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } else {
        _gallerySelection = YES;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}


#pragma mark - TextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.activeTextView = nil;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self.annotationTextView becomeFirstResponder];
    return YES;
}

#pragma mark - TextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    self.activeTextView = textView;
    return YES;
}

#pragma mark - ImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (_gallerySelection) {
        [_images addObject:image];
        [self.galletyCollectionView reloadData];
    } else {
        [self.imageView setImage:image];
    }
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Internal

- (void)moveViewTo:(CGFloat)yPosition
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.35f];
    CGRect frame = self.view.frame;
    frame.origin.y = yPosition;
    [self.view setBounds:frame];
    [UIView commitAnimations];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
}

- (CGFloat)pointsToShowView:(UIView *)view behiedKeyboardWithHeight:(CGFloat)height
{
    if (view.frame.origin.y + view.frame.size.height + kHeightFromKeyboard > self.view.frame.size.height - height) {
        return height - (self.view.frame.size.height - (view.frame.origin.y + view.frame.size.height + kHeightFromKeyboard));
    }
    return 0;
}

- (void)hideKeyboard
{
    [self.tapOnMainViewRecognizer setEnabled:NO];
    [self.titleTextField resignFirstResponder];
    [self.annotationTextView resignFirstResponder];
    [self.mainTextView resignFirstResponder];
    if (self.currentOffset) {
        self.currentOffset = 0;
    }
}

@end
