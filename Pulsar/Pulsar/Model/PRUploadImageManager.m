//
//  PRUploadImageManager.m
//  Pulsar
//
//  Created by fantom on 17.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRUploadImageManager.h"
#import "PRLocalDataStore.h"
#import "UploadTask+CoreDataProperties.h"

@interface PRUploadImageManager()

@property (strong, nonatomic) NSOperationQueue *processingQueue;
@property (strong, atomic) NSMutableArray<UploadTask *> *uploadStack;
@property (strong, nonatomic) UploadTask *currentUploadingTask;

@end

@implementation PRUploadImageManager{
    BOOL _isRuning;
}

static NSString * const kTableName = @"UploadTask";
static NSString * const kArticleClassName = @"Article";

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.processingQueue = [[NSOperationQueue alloc] init];
        self.processingQueue.maxConcurrentOperationCount = 1;
        self.processingQueue.name = @"upload article attachments queue";
        
        [self loadUnloadedTasks];
    }
    return self;
}

- (void)loadUnloadedTasks
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kTableName];
    [[[PRLocalDataStore sharedInstance] uploadBackgroundContext] performBlock:^{
        NSArray *result = [[[PRLocalDataStore sharedInstance] uploadBackgroundContext] executeFetchRequest:request error:nil];
        if ([result count]) {
            self.uploadStack = [[NSMutableArray alloc] initWithArray:result];
        } else {
            self.uploadStack = [NSMutableArray new];
        }
        [self startUpload];
    }];
}

- (void)startUpload
{
    if (_isRuning) return;
    _isRuning = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        while ([self.uploadStack count]) {
            dispatch_group_t uploadGroup = dispatch_group_create();
            dispatch_group_enter(uploadGroup);
            PRUploadMediaOperation *uploadOpreation = [self nextOperation];
            uploadOpreation.completionBlock = ^(){
                [self removeCurrentTask];
                dispatch_group_leave(uploadGroup);
            };
            [self.processingQueue addOperation:uploadOpreation];
            dispatch_group_wait(uploadGroup, DISPATCH_TIME_FOREVER);
        }
        _isRuning = NO;
    });
}

- (void)removeCurrentTask
{
    UploadTask *delete = self.currentUploadingTask;
    [[[PRLocalDataStore sharedInstance] uploadBackgroundContext] performBlock:^{
        [[[PRLocalDataStore sharedInstance] uploadBackgroundContext] deleteObject:delete];
        [[[PRLocalDataStore sharedInstance] uploadBackgroundContext] save:nil];
    }];
    [self.uploadStack removeObject:delete];
}

- (PRUploadMediaOperation *)nextOperation
{
    if ([self.uploadStack count]) {
        self.currentUploadingTask = [self.uploadStack lastObject];
        PRUploadMediaOperation *uploadOperation = [[PRUploadMediaOperation alloc] init];
        uploadOperation.uploadImage = [UIImage imageWithData:self.currentUploadingTask.data];
        PRRemotePointer *remotePointer = [[PRRemotePointer alloc] initWithClass:kArticleClassName remoteObjectId:self.currentUploadingTask.identifier];
        uploadOperation.article = remotePointer;
        [uploadOperation setQueuePriority:NSOperationQueuePriorityLow];
        return uploadOperation;
    }
    
    return nil;
}

- (void)uploadImage:(UIImage *)image articleWithId:(NSString *)articleRemoteId
{
    if (!image || ![articleRemoteId length]) {
        return;
    }
    
    [[[PRLocalDataStore sharedInstance] uploadBackgroundContext] performBlock:^{
        UploadTask *newTask = [NSEntityDescription insertNewObjectForEntityForName:kTableName inManagedObjectContext:[[PRLocalDataStore sharedInstance] uploadBackgroundContext]];
        newTask.identifier = articleRemoteId;
        newTask.data = UIImagePNGRepresentation(image);
        [[[PRLocalDataStore sharedInstance] uploadBackgroundContext] save:nil];
        [self.uploadStack addObject:newTask];
        [self startUpload];
    }];
}

- (void)performUploadOperation:(PRUploadMediaOperation *)uploadOperation
{
    NSOperation *operation = uploadOperation;
    [operation setQueuePriority:NSOperationQueuePriorityHigh];
    [self.processingQueue addOperation:operation];
}

@end
