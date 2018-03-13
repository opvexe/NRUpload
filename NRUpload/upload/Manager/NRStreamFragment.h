//
//  NRStreamFragment.h
//  NRUpload
//
//  Created by Facebook on 2018/3/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NRStreamFragment : NSObject<NSCoding>

#pragma mark - 上传文件片流
//片的唯一标识
@property (nonatomic,copy)NSString          *fragmentId;
 //片的大小
@property (nonatomic,assign)NSUInteger      fragmentSize;
//片的偏移量
@property (nonatomic,assign)NSUInteger      fragementOffset;
//上传状态 YES上传成功,NO失败
@property (nonatomic,assign)BOOL            fragmentStatus;

@end
