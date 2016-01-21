//
//  PRLocalCategory.h
//  Pulsar
//
//  Created by fantom on 20.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRRemoteCategory.h"

#warning must be replased NSManagedObject from model
@interface PRLocalCategory : NSObject

@property (strong, nonatomic, readonly) NSString *identifier;
@property (strong, nonatomic, readonly) NSString *title;
@property (nonatomic, getter=isSelected) BOOL selected;

- (instancetype)initWithRemoteCategory:(PRRemoteCategory *)remoteCategory;

@end
