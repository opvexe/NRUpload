//
//  NSString+md5.h
//  NRUpload
//
//  Created by Facebook on 2018/3/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (md5)

+(NSString *)fileKey;

+(NSString*)fileKeyMD5WithPath:(NSString*)path;

@end
