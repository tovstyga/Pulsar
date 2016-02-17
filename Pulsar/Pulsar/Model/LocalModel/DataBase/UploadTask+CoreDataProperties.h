//
//  UploadTask+CoreDataProperties.h
//  Pulsar
//
//  Created by fantom on 17.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "UploadTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface UploadTask (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSData *data;

@end

NS_ASSUME_NONNULL_END
