//
//  PRLocalDataStore.h
//  Pulsar
//
//  Created by fantom on 29.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PRLocalDataStore : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *mainContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *backgroundContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *uploadBackgroundContext;

+ (instancetype)sharedInstance;

- (NSURL *)applicationDocumentsDirectory;
- (void)saveMainContextAndWait:(BOOL)wait;
- (void)saveBackgroundContext;

@end
