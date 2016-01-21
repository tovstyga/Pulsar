//
//  PRRemoteResults.m
//  Pulsar
//
//  Created by fantom on 13.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRRemoteResults.h"

@implementation PRRemoteResults

static NSString * const kResultKey = @"results";

+ (NSArray *)resultsWithData:(id)jsonCompatableOblect contentType:(Class)prototype
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if ([jsonCompatableOblect isKindOfClass:[NSDictionary class]] && [prototype conformsToProtocol:@protocol(PRJsonCompatable)]) {
        NSArray *sources = [(NSDictionary *)jsonCompatableOblect objectForKey:kResultKey];
        for (id sourceObject in sources) {
            if ([sourceObject isKindOfClass:[NSDictionary class]]) {
                NSObject *resultObject = [[prototype alloc] initWithJSON:sourceObject];
                [result addObject:resultObject];
            }
        }
    }
    
    return result;
}

@end
