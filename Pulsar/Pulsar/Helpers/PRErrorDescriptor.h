//
//  PRErrorDescriptor.h
//  Pulsar
//
//  Created by fantom on 05.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRErrorDescriptor : NSObject

+ (instancetype)sharedInstance;

- (NSString *)descriptionForError:(NSError *)error;

@end
