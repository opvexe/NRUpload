//
//  NRUploadManager.h
//  NRUpload
//
//  Created by Facebook on 2018/3/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NRFileStreamConfiguration.h"
#import "NRUploadTask.h"

@interface NRUploadManager : NSObject
//获得管理类单例对象
+ (instancetype _Nonnull )shardUploadManager;

@property (nonatomic,readonly)NSMutableDictionary * _Nullable fileStreamDict;
//总任务数
@property (nonatomic,readonly)NSMutableDictionary * _Nullable allTasks;
//正在上传中的任务
@property (nonatomic,readonly)NSMutableDictionary * _Nullable uploadingTasks;
//正在等待上传的任务
@property (nonatomic,readonly)NSMutableDictionary * _Nullable uploadWaitTasks;
//已经上传完的任务
@property (nonatomic,readonly)NSMutableDictionary * _Nullable uploadEndTasks;
//同时上传的任务数
@property (nonatomic,readonly)NSInteger uploadMaxNum;
//配置的上传路径
@property (nonatomic,readonly)NSURL * _Nullable url;
//配置的请求体
@property (nonatomic,readonly)NSMutableURLRequest * _Nullable request;


//配置全局默认参数
/**
 @param request 默认请求头
 @param num 最大任务数
 */
- (void)config:(NSMutableURLRequest * _Nonnull)request maxTask:(NSInteger)num;

//根据文件路径创建上传任务
- (NRUploadTask *_Nullable)createUploadTask:(NSString *_Nonnull)filePath;


/**
 暂停一个上传任务
 
 @param fileStream 上传文件的路径
 */
- (void)pauseUploadTask:(NRFileStreamConfiguration *_Nonnull)fileStream;

/**
 继续开始一个上传任务
 
 @param fileStream 上传文件的路径
 */
- (void)resumeUploadTask:(NRFileStreamConfiguration *_Nonnull)fileStream;

/**
 删除一个上传任务，同时会删除当前任务上传的缓存数据
 
 @param fileStream 上传文件的路径
 */
- (void)removeUploadTask:(NRFileStreamConfiguration *_Nonnull)fileStream;

/**
 暂停所有上传任务
 */
- (void)pauseAllUploadTask;

/**
 删除所有上传任务
 */
- (void)removeAllUploadTask;
@end
