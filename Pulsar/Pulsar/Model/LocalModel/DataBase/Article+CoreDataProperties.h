//
//  Article+CoreDataProperties.h
//  Pulsar
//
//  Created by fantom on 01.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Article.h"

NS_ASSUME_NONNULL_BEGIN

@interface Article (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *annotation;
@property (nullable, nonatomic, retain) NSString *author;
@property (nullable, nonatomic, retain) NSNumber *canDislike;
@property (nullable, nonatomic, retain) NSNumber *canLike;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSDate *updatedDate;
@property (nullable, nonatomic, retain) NSNumber *rating;
@property (nullable, nonatomic, retain) NSString *remoteIdentifier;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) InterestCategory *category;
@property (nullable, nonatomic, retain) Media *image;
@property (nullable, nonatomic, retain) GeoPoint *location;
@property (nullable, nonatomic, retain) NSSet<Media *> *media;

@end

@interface Article (CoreDataGeneratedAccessors)

- (void)addMediaObject:(Media *)value;
- (void)removeMediaObject:(Media *)value;
- (void)addMedia:(NSSet<Media *> *)values;
- (void)removeMedia:(NSSet<Media *> *)values;

@end

NS_ASSUME_NONNULL_END
