//
//  PRMapViewInteractor.m
//  Pulsar
//
//  Created by fantom on 21.01.16.
//  Copyright © 2016 TAB. All rights reserved.
//

#import "PRMapViewInteractor.h"
#import "PRDataProvider.h"
#import "PRErrorDescriptor.h"
#import "PRLocalGeoPoint.h"

@implementation PRMapViewInteractor

- (void)addPointWithName:(NSString *)name
               longitude:(float)longitude
                latitude:(float)latitude
              completion:(void(^)(BOOL success, NSString *errorMessage))completion
{
    __weak typeof(self) wSelf = self;
    PRLocalGeoPoint *geoPoint = [[PRLocalGeoPoint alloc] initWithLatitude:latitude longitude:longitude title:name];
    [[PRDataProvider sharedInstance] addGeoPoint:geoPoint completion:^(NSError *error) {
        if (!error) {
            __strong typeof(wSelf) sSelf = wSelf;
            if (sSelf && [sSelf.delegate respondsToSelector:@selector(didAddNewLocation)]) {
                [sSelf.delegate didAddNewLocation];
            }
        }
        if (completion) {
            if (error) {
                completion(NO, [PRErrorDescriptor descriptionForError:error]);
            } else {
                completion(YES, nil);
            }
        }
    }];
}

@end
