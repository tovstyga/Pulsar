//
//  PRArticleCollection.h
//  Pulsar
//
//  Created by fantom on 02.02.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PRArticleFetch) {
    PRArticleFetchHour = 0,
    PRArticleFetchDay,
    PRArticleFetchWeek,
    PRArticleFetchMonth,
    PRArticleFetchYear
};

@interface PRArticleCollection : NSObject

- (void)setFetchResult:(NSArray *)result forKey:(PRArticleFetch)key;
- (NSArray *)fetchResultForKey:(PRArticleFetch)key;

@end
