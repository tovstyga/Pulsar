//
//  PRCreationViewController.h
//  Pulsar
//
//  Created by fantom on 25.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRootViewController.h"
#import "PRCreationViewInteractorProtocol.h"

@interface PRCreationViewController : PRRootViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) id<PRCreationViewInteractorProtocol> interactor;

@end
