//
//  PRContentViewDelegateProtocol.h
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

@protocol PRContentViewDelegate <NSObject>

- (void)menuWillOpen;
- (void)menuDidOpen;

- (void)menuWillClose;
- (void)menuDidClose;

@end
