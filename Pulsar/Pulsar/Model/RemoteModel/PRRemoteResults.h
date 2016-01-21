//
//  PRRemoteResults.h
//  Pulsar
//
//  Created by fantom on 13.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRJsonCompatable.h"

@interface PRRemoteResults : NSObject

+ (NSArray *)resultsWithData:(id)jsonCompatableOblect contentType:(Class)prototype;

@end
