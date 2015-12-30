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

//classes

#import "PRLoginViewInteractor.h"
#import "PRRestoreAccountInteractor.h"
#import "PRRegistrationViewInteractor.h"

#import "PRLoginViewController.h"
#import "PRRegistrationViewController.h"
#import "PRRestoreAccountViewController.h"

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

- (void)configureViewController:(UIViewController *)viewController
{
    if ([viewController isMemberOfClass:[PRLoginViewController class]]) {
        [(PRLoginViewController *)viewController setInteractor:[self loginInteractor]];
    } else if ([viewController isMemberOfClass:[PRRegistrationViewController class]]) {
        [(PRRegistrationViewController *)viewController setInteractor:[self registrationInteractor]];
    } else if ([viewController isMemberOfClass:[PRRestoreAccountViewController class]]) {
        [(PRRestoreAccountViewController *)viewController setInteractor:[self restoreAccountInteractor]];
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

@end
