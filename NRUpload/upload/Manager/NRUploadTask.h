//
//  NRUploadTask.h
//  NRUpload
//
//  Created by Facebook on 2018/3/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRFileStreamConfiguration.h"


typedef void(^finishHandler)(NRFileStreamConfiguration * _Nullable fileStream, NSError * _Nullable error);
typedef void(^success)(NRFileStreamConfiguration * _Nullable fileStream);

@interface NRUploadTask : NSObject

@property (nonatomic,strong)NRFileStreamConfiguration * _Nullable fileStream;
//当前上传任务的URL
@property (nonatomic,readonly,strong)NSURL * _Nullable url;
//当前上传任务的参数
@property (nonatomic,readonly,strong)NSMutableDictionary * _Nullable param;
//任务对象的执行状态
@property (nonatomic,readonly,assign)NSURLSessionTaskState taskState;
//上传任务的唯一ID
@property (nonatomic,readonly,copy)NSString * _Nullable ID;


/*!
 根据一个文件分片模型创建一个上传任务，执行 taskResume 方法开始上传
 */
+ (instancetype _Nonnull )initWithStreamModel:(NRFileStreamConfiguration * _Nonnull)fileStream;

/*!
 监听一个已存在的上传任务的状态
 */
- (void)listenTaskExeCallback:(finishHandler _Nonnull)block
                      success:(success _Nonnull)successBlock;

/*!
 根据一个文件分片模型的字典创建一个上传任务(处于等待状态)字典
 */
+ (NSMutableDictionary<NSString*,NRUploadTask*> *_Nullable)uploadTasksWithDict:(NSDictionary<NSString*,NRFileStreamConfiguration*> *_Nullable)dict;

/**
 根据一个文件分片模型创建一个上传任务,执行 startExe 方法开始上传,结果会由block回调出来
 */
- (instancetype _Nonnull)initWithStreamModel:(NRFileStreamConfiguration *_Nonnull)fileStream
                                      finish:(finishHandler _Nonnull)block
                                     success:(success _Nonnull)successBlock;
/*!
 * 继续/开始上传
 */
- (void)taskResume;

/*!
 * 取消/暂停上传
 */
- (void)taskCancel;

@end
