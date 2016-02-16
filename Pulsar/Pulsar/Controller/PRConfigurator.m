//
//  PRConfigurator.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRConfigurator.h"

#import "PRRestoreAccountViewInteractorProtocol.h"
#import "RPRegistrationViewInteractorProtocol.h"
#import "RPLoginViewInteractorProtocol.h"
#import "PRContentViewInteractorProtocol.h"
#import "PRMenuViewInteractorProtocol.h"
#import "PRMapViewInteractorProtocol.h"
#import "PRMapInteractorDelegate.h"
#import "PRDetailsViewInteractorProtocol.h"
#import "PRCreationViewInteractorProtocol.h"
#import "PRRootInteractorProtocol.h"

#import "PRContentViewController.h"
#import "PRMenuViewController.h"

#import "PREmailValidator.h"
#import "PRDataProvider.h"
#import "PRErrorDescriptor.h"

@implementation PRConfigurator

static PRConfigurator *sharedInstance;

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    } else {
        return [super init];
    }
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PRConfigurator alloc] init];
    });
    return sharedInstance;
}

- (void)configureViewController:(UIViewController *)viewController sourceViewController:(UIViewController *)sourceViewController
{
    UIViewController *configuredController = viewController;
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        configuredController = [(UINavigationController *)viewController topViewController];
    } else if ([viewController isMemberOfClass:[PRMenuViewController class]]) {
        if ([viewController conformsToProtocol:@protocol(PRContentViewDelegate)] && [sourceViewController isKindOfClass:[PRContentViewController class]]) {
            [(PRContentViewController *)sourceViewController setDelegate:(id<PRContentViewDelegate>)viewController];
        }
    }
    [self configureViewController:configuredController withDelegate:sourceViewController];
}

#pragma mark - Interactors

- (void)configureViewController:(UIViewController *)controller withDelegate:(id)delegate;
{
    if (![controller isKindOfClass:[PRRootViewController class]]) {
        return;
    }
    
    if ([[(PRRootViewController *)controller interactor] conformsToProtocol:@protocol(PRRootInteractorProtocol)]) {
        id<PRRootInteractorProtocol> rootInteractor = (id<PRRootInteractorProtocol>)[(PRRootViewController *)controller interactor];
        [rootInteractor setDataProvider:[PRDataProvider sharedInstance]];
        [rootInteractor setErrorDescriptor:[PRErrorDescriptor sharedInstance]];
        
        if ([rootInteractor conformsToProtocol:@protocol(PRRestoreAccountViewInteractorProtocol)]) {
            [(id<PRRestoreAccountViewInteractorProtocol>)rootInteractor setValidator:[PREmailValidator sharedInstance]];
        } else if ([rootInteractor conformsToProtocol:@protocol(RPRegistrationViewInteractorProtocol)]) {
            [(id<RPRegistrationViewInteractorProtocol>)rootInteractor setValidator:[PREmailValidator sharedInstance]];
        } else if ([rootInteractor conformsToProtocol:@protocol(PRMenuViewInteractorProtocol)]) {
            if ([delegate conformsToProtocol:@protocol(PRMenuInteractorDelegate)]) {
                [(id<PRMenuViewInteractorProtocol>)rootInteractor setDelegate:delegate];
            }
        } else if ([rootInteractor conformsToProtocol:@protocol(PRMapViewInteractorProtocol)]) {
            if ([delegate conformsToProtocol:@protocol(PRMapInteractorDelegate)]) {
                [(id<PRMapViewInteractorProtocol>)rootInteractor setDelegate:delegate];
            }
        }
    }
}

@end
