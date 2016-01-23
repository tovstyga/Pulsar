//
//  PRConfigurator.m
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#import "PRConfigurator.h"

//protocols

#import "PRRestoreAccountViewInteractorProtocol.h"
#import "RPRegistrationViewInteractorProtocol.h"
#import "RPLoginViewInteractorProtocol.h"
#import "PRContentViewInteractorProtocol.h"
#import "PRMenuViewInteractorProtocol.h"
#import "PRMapViewInteractorProtocol.h"
#import "PRMapInteractorDelegate.h"

//interactors

#import "PRLoginViewInteractor.h"
#import "PRRestoreAccountInteractor.h"
#import "PRRegistrationViewInteractor.h"
#import "PRContentViewInteractor.h"
#import "PRMenuViewInteractor.h"
#import "PRMapViewInteractor.h"

//controllers

#import "PRLoginViewController.h"
#import "PRRegistrationViewController.h"
#import "PRRestoreAccountViewController.h"
#import "PRContentViewController.h"
#import "PRMenuViewController.h"
#import "PRMapViewController.h"

#import "PREmailValidator.h"

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
    if ([viewController isMemberOfClass:[PRLoginViewController class]]) {
        [(PRLoginViewController *)viewController setInteractor:[self loginInteractor]];
    } else if ([viewController isMemberOfClass:[PRRegistrationViewController class]]) {
        [(PRRegistrationViewController *)viewController setInteractor:[self registrationInteractor]];
    } else if ([viewController isMemberOfClass:[PRRestoreAccountViewController class]]) {
        [(PRRestoreAccountViewController *)viewController setInteractor:[self restoreAccountInteractor]];
    } else if ([viewController isMemberOfClass:[PRContentViewController class]]) {
        [(PRContentViewController *)viewController setInteractor:[self contentInteractor]];
    } else if ([viewController isMemberOfClass:[PRMenuViewController class]]) {
        [(PRMenuViewController *)viewController setInteractor:[self menuInteractorWithDelegate:sourceViewController]];
        if ([viewController conformsToProtocol:@protocol(PRContentViewDelegate)] && [sourceViewController isKindOfClass:[PRContentViewController class]]) {
            [(PRContentViewController *)sourceViewController setDelegate:(id<PRContentViewDelegate>)viewController];
        }
    } else if ([viewController isMemberOfClass:[PRMapViewController class]]) {
        [(PRMapViewController *)viewController setInteractor:[self mapInteractorWithDelegate:sourceViewController]];
    }
}

#pragma mark - Interactors

- (id<PRRestoreAccountViewInteractorProtocol>)restoreAccountInteractor
{
    PRRestoreAccountInteractor *interactor = [[PRRestoreAccountInteractor alloc] init];
    interactor.validator = [PREmailValidator sharedInstance];
    return interactor;
}

- (id<RPRegistrationViewInteractorProtocol>)registrationInteractor
{
    PRRegistrationViewInteractor *interactor = [[PRRegistrationViewInteractor alloc] init];
    interactor.validator = [PREmailValidator sharedInstance];
    return interactor;
}

- (id<RPLoginViewInteractorProtocol>)loginInteractor
{
    return [[PRLoginViewInteractor alloc] init];
}

- (id<PRContentViewInteractorProtocol>)contentInteractor
{
    return [[PRContentViewInteractor alloc] init];
}

- (id<PRMenuViewInteractorProtocol>)menuInteractorWithDelegate:(id)delegate;
{
    PRMenuViewInteractor *interactor = [[PRMenuViewInteractor alloc] init];
    if ([delegate conformsToProtocol:@protocol(PRMenuInteractorDelegate)]) {
        interactor.delegate = delegate;
    }
    return interactor;
}

- (id<PRMapViewInteractorProtocol>)mapInteractorWithDelegate:(id)delegate;
{
    PRMapViewInteractor *interactor = [[PRMapViewInteractor alloc] init];
    if ([delegate conformsToProtocol:@protocol(PRMapInteractorDelegate)]) {
        interactor.delegate = delegate;
    }
    return interactor;
}

@end
