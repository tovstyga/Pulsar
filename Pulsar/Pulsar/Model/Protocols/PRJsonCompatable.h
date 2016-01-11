//
//  PRJsonCompatable.h
//  Pulsar
//
//  Created by fantom on 30.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

@protocol PRJsonCompatable <NSObject>

- (instancetype)initWithJSON:(id)jsonCompatableOblect;
- (id)toJSONCompatable;

@end