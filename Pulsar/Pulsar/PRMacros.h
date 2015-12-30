//
//  PRMacros.h
//  Pulsar
//
//  Created by fantom on 24.12.15.
//  Copyright © 2015 TAB. All rights reserved.
//

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                                   green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
                                                    blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
                                                   alpha:1.0]

#define UIColorFromRGBWithAlpha(rgbValue,a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                                            green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
                                                             blue:((float)(rgbValue & 0xFF))/255.0  \
                                                            alpha:a]