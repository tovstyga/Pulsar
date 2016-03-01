//
//  PRMenuInteractorDelegateProtocol.h
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

@protocol PRMenuInteractorDelegate <NSObject>

- (void)willUpdateUserSettings;
- (void)didUpdateUserSettings;

- (void)logoutAction;

@end
