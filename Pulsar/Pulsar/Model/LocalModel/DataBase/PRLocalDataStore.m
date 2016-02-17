//
//  PRLocalDataStore.m
//  Pulsar
//
//  Created by fantom on 29.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRLocalDataStore.h"

@interface PRLocalDataStore()

@property (readonly, strong, nonatomic) NSManagedObjectContext *rootObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation PRLocalDataStore

static PRLocalDataStore *sharedInstance;

- (instancetype)init
{
    if (sharedInstance) {
        return sharedInstance;
    }
    self = [super init];
    if (self) {
    
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[PRLocalDataStore alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Core Data stack

@synthesize rootObjectContext = _rootObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize mainContext = _mainContext;
@synthesize backgroundContext = _backgroundContext;
@synthesize uploadBackgroundContext = _uploadBackgroundContext;

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PRDataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PRDataModel.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)rootObjectContext {
    if (_rootObjectContext != nil) {
        return _rootObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _rootObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_rootObjectContext setPersistentStoreCoordinator:coordinator];
    return _rootObjectContext;
}

- (NSManagedObjectContext *)mainContext
{
    if (_mainContext != nil) {
        return _mainContext;
    }
    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_mainContext setParentContext:self.rootObjectContext];
    return _mainContext;
}

- (NSManagedObjectContext *)backgroundContext
{
    if (_backgroundContext != nil) {
        return _backgroundContext;
    }
    _backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_backgroundContext setParentContext:self.mainContext];
    return _backgroundContext;
}

- (NSManagedObjectContext *)uploadBackgroundContext
{
    if (_uploadBackgroundContext != nil) {
        return _uploadBackgroundContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _uploadBackgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_uploadBackgroundContext setPersistentStoreCoordinator:coordinator];
    return _uploadBackgroundContext;
}

#pragma mark - Core Data Saving support

- (void)saveBackgroundContext
{
    [self.backgroundContext performBlockAndWait:^{
        [self saveContext:self.backgroundContext];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveMainContextAndWait:NO];
    });
}

- (void)saveMainContextAndWait:(BOOL)wait
{
    [self.mainContext performBlockAndWait:^{
        [self saveContext:self.mainContext];
    }];
    
    void (^saveRootContext) (void) = ^{
        [self saveContext:self.rootObjectContext];
    };
    
    if (wait) {
        [self.rootObjectContext performBlockAndWait:saveRootContext];
    } else {
        [self.rootObjectContext performBlock:saveRootContext];
    }
}

- (void)saveContext:(NSManagedObjectContext *)context {
    NSManagedObjectContext *managedObjectContext = context;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
