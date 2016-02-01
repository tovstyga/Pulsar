//
//  Category+CoreDataProperties.h
//  Pulsar
//
//  Created by fantom on 01.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "InterestCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface InterestCategory (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *remoteIdentifier;

@end

NS_ASSUME_NONNULL_END
