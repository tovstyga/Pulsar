//
//  PRRemoteQuery.h
//  Pulsar
//
//  Created by fantom on 19.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRRemotePointer.h"
#import "PRRemoteBatchRequestObject.h"

@interface PRRemoteQuery : NSObject

+ (instancetype)sharedInstance;

- (NSDictionary *)categoriesQueryForUser:(PRRemotePointer *)pointer;

- (NSDictionary *)addRelationField:(NSString *)fieldName objects:(NSArray *)pointers;

- (NSDictionary *)removeRelationField:(NSString *)fieldName objects:(NSArray *)pointers;

- (NSDictionary *)batchQueryWithObjects:(NSArray *)batchRequestObjects;

- (NSDictionary *)mediaForArticle:(PRRemotePointer *)pointer;

@end
