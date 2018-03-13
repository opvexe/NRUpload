//
//  NRUploadTask.m
//  NRUpload
//
//  Created by Facebook on 2018/3/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "NRUploadTask.h"
#import "NRFileManager.h"
#import "Const.h"
#import "NRUploadManager.h"
#import "NRStreamFragment.h"
#import "NSString+md5.h"

//分隔符
#define Boundary @"1a2b3c"
//一般换行
#define Wrap1 @"\r\n"
//key-value换行
#define Wrap2 @"\r\n\r\n"
//开始分割
#define StartBoundary [NSString stringWithFormat:@"--%@%@",Boundary,Wrap1]
//文件分割完成
#define EndBody [NSString stringWithFormat:@"--%@--",Boundary]
//一个片段上传失败默认重试3次
#define REPEAT_MAX 3
//沙河文件路径
#define plistPath [[NRFileManager cachesDir] stringByAppendingPathComponent:uploadPlist]

@interface NRUploadTask()
@property (nonatomic,strong)NSURLSessionUploadTask *uploadTask;
@property (nonatomic,strong)NSMutableURLRequest *request;
@property (nonatomic,readwrite)NSURL * url;
@property (nonatomic,readwrite)NSString *ID;

@property (nonatomic,readwrite)NSMutableDictionary *param;//上传时参数
@property (nonatomic,readwrite)NSURLSessionTaskState taskState;
//片段上传成功上传的回调block
@property (nonatomic,copy)finishHandler finishBlock;
//整体上传成功上传的回调block
@property (nonatomic,copy)success successBlock;
//片段编号这一参数的参数名
@property (nonatomic,copy)NSString *chunkNumName;
//片段完成上传后的参数
@property (nonatomic,copy)NSDictionary *lastParam;
//片段完成上传后的编号
@property (nonatomic,assign)NSInteger chunkNo;
//重试次数
@property (nonatomic,assign)NSInteger taskRepeatNum;
//记录状态更改
@property (nonatomic,assign)BOOL isSuspendedState;

@property (nonatomic,strong)NRUploadManager *uploadManager;
@end
@implementation NRUploadTask


-(NSMutableURLRequest*)uploadRequest{
    if ([NRUploadManager shardUploadManager].request) {
        _request = [NRUploadManager shardUploadManager].request;
    }else{
        NSLog(@"请配置上传任务的request");
    }
    return _request;
}

-(NSData*)taskRequestBodyWithParam:(NSDictionary *)param uploadData:(NSData *)data{
    
    NSMutableData* totlData=[NSMutableData new];
    NSArray* allKeys=[param allKeys];
    for (int i=0; i<allKeys.count; i++){
        NSString *disposition = [NSString stringWithFormat:@"%@Content-Disposition: form-data; name=\"%@\"%@",StartBoundary,allKeys[i],Wrap2];
        NSString* object=[param objectForKey:allKeys[i]];
        disposition =[disposition stringByAppendingString:[NSString stringWithFormat:@"%@",object]];
        disposition =[disposition stringByAppendingString:Wrap1];
        [totlData appendData:[disposition dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSString *body=[NSString stringWithFormat:@"%@Content-Disposition: form-data; name=\"picture\"; filename=\"%@\";Content-Type:video/mpeg4%@",StartBoundary,@"file",Wrap2];
    [totlData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [totlData appendData:data];
    [totlData appendData:[Wrap1 dataUsingEncoding:NSUTF8StringEncoding]];
    [totlData appendData:[EndBody dataUsingEncoding:NSUTF8StringEncoding]];
    return totlData;
}

- (void)checkParamFromServer:(NRFileStreamConfiguration *_Nonnull)fileStream
               paramCallback:(void(^ _Nullable)(NSString *_Nonnull chunkNumName,NSDictionary *_Nullable param))paramBlock{
    
    NSString *uploadFileInfoUrl=[NSString stringWithFormat:@"%@/upload/checkFileChunk",CURRENT_API];
    NSURL *url = [NSURL URLWithString:uploadFileInfoUrl];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *args = [NSString stringWithFormat:@"bizId=%@&fileName=%@&saveName=%@&chunks=%@",fileStream.bizId,fileStream.fileName,fileStream.md5String,[NSString stringWithFormat:@"%zd",fileStream.streamFragments.count]];
    NSLog(@"%@",args);
    request.HTTPMethod = @"POST";//设置请求类型
    [request setValue:@"v1" forHTTPHeaderField:@"api_version"];
    request.HTTPBody = [args dataUsingEncoding:NSUTF8StringEncoding];//设置参数
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *postTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if ([dict[@"code"] isEqualToString:@"500"]) {
                NSLog(@"%@",dict[@"desc"]);
                return;
            }
            NSMutableDictionary *tmpParam = [NSMutableDictionary dictionary];
            [tmpParam setDictionary:dict[@"data"]];
            paramBlock(@"chunk",tmpParam);
        }
    }];
    [postTask resume];
    
}

#pragma mark - 上传任务

-(void)uploadTaskWithUrl:(NSURL *)url param:(NSDictionary *)param uploadData:(NSData *)data completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler{
    
    if (_isSuspendedState){
        [self taskCancel];
        return;
    }
    _param = [NSMutableDictionary dictionaryWithDictionary:param];;
    NSURLSession *session = [NSURLSession sharedSession];
    self.uploadTask = [session uploadTaskWithRequest:[self uploadRequest] fromData:[self taskRequestBodyWithParam:param uploadData:data] completionHandler:completionHandler];
    self.taskState = _uploadTask.state;
    [_uploadTask resume];
}

/*!
 * 上传文件相关信息，返回文件上传相关参数
 */
- (void)postFileInfo{
    __weak typeof(self) weekSelf = self;
    [self checkParamFromServer:_fileStream paramCallback:^(NSString * _Nonnull chunkNumName, NSDictionary * _Nullable param) {
        weekSelf.chunkNumName = chunkNumName;
        weekSelf.param = [NSMutableDictionary dictionaryWithDictionary:param];
        [weekSelf startExe];
    }];
}

//上传文件的核心方法
- (void)startExe{
    //判断无参数的情况下先将文件信息上传并获得参数
    if (!_param) [self postFileInfo];
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    
    if (_fileStream.fileStatus == CWUploadStatusFinished && _successBlock) {
        _successBlock(_fileStream);
        return;
    };
    for (NSInteger i=0; i<_fileStream.streamFragments.count; i++) {
        NRStreamFragment *fragment = _fileStream.streamFragments[i];
        if (fragment.fragmentStatus) continue;
        dispatch_group_async(group, queue, ^{
            @autoreleasepool {
                NSData *data = [_fileStream readDateOfFragment:fragment];
                __weak typeof(self) weekSelf = self;
                [_param setObject:[NSString stringWithFormat:@"%zd",(i+1)] forKey:_chunkNumName];
                //                NSLog(@"*******参数*******\n%@",_param);
                [self uploadTaskWithUrl:_url param:_param uploadData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                    if (!error && httpResponse.statusCode==200) {
                        _taskRepeatNum = 0;
                        fragment.fragmentStatus = YES;
                        _fileStream.fileStatus = CWUploadStatusUpdownloading;
                        [weekSelf archTaskFileStream];
                        weekSelf.lastParam = _param;
                        weekSelf.chunkNo = i+1;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (_finishBlock) _finishBlock(_fileStream,nil);
                            [self sendNotionWithKey:@"CWUploadTaskExeing" userInfo:@{@"fileStream":_fileStream,@"lastParam":_lastParam,@"indexNo":@(_chunkNo)}];
                        });
                        dispatch_semaphore_signal(semaphore);
                    }else{
                        if (_taskRepeatNum<REPEAT_MAX) {
                            _taskRepeatNum++;
                            [weekSelf startExe];
                        }else{
                            _fileStream.fileStatus = CWUploadStatusFailed;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (_finishBlock) _finishBlock(_fileStream,error);
                                [self sendNotionWithKey:@"CWUploadTaskExeError" userInfo:@{@"fileStream":_fileStream,@"error":error}];
                            });
                            [weekSelf deallocSession];
                            return;
                        }
                    }
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        });
    }

    dispatch_group_notify(group, queue, ^{
        _fileStream.fileStatus = CWUploadStatusFinished;
        [self archTaskFileStream];
        if (_finishBlock) _finishBlock(_fileStream,nil);
        [self deallocSession];
    });
}

/*!
 根据一个文件分片模型创建一个上传任务，执行 taskResume 方法开始上传
 */
+ (instancetype)initWithStreamModel:(NRFileStreamConfiguration * _Nonnull)fileStream{
    
    NRUploadTask *task = [[NRUploadTask alloc]init];
    task.fileStream = fileStream;
    task.isSuspendedState = NO;
    task.url = [NRUploadManager shardUploadManager].url;
    return task;
}

/*!
 监听一个已存在的上传任务的状态
 */
- (void)listenTaskExeCallback:(finishHandler _Nonnull)block
                      success:(success _Nonnull)successBlock{
    self.finishBlock = block;
    self.successBlock = successBlock;
    if (_finishBlock) _finishBlock(_fileStream,nil);
}

/*!
 根据一个文件分片模型的字典创建一个上传任务(处于等待状态)字典
 */
+ (NSMutableDictionary<NSString*,NRUploadTask*> *_Nullable)uploadTasksWithDict:(NSDictionary<NSString*,NRFileStreamConfiguration*> *_Nullable)dict{
    
    NSMutableDictionary *taskDict = [NSMutableDictionary dictionary];
    for (NSString *key in dict.allKeys) {
        NRFileStreamConfiguration *fs = [dict objectForKey:key];
        NRUploadTask *task = [NRUploadTask initWithStreamModel:fs];
        [taskDict setValue:task forKey:key];
    }
    return taskDict;
}

/**
 根据一个文件分片模型创建一个上传任务,执行 startExe 方法开始上传,结果会由block回调出来
 */
- (instancetype _Nonnull)initWithStreamModel:(NRFileStreamConfiguration *_Nonnull)fileStream
                                      finish:(finishHandler _Nonnull)block
                                     success:(success _Nonnull)successBlock{
    if (self = [super init]) {
        self.fileStream = fileStream;
        _finishBlock = block;
        _successBlock = successBlock;
    }
    return self;
}
/*!
 * 继续/开始上传
 */
- (void)taskResume{
    
    _isSuspendedState = NO;
    if (!(self.uploadManager.uploadingTasks.count<self.uploadManager.uploadMaxNum)) {
        _fileStream.fileStatus = CWUploadStatusWaiting;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_successBlock)  _successBlock(_fileStream);
            [self sendNotionWithKey:@"CWUploadTaskExeEnd" userInfo:@{@"fileStream":_fileStream}];
        });
        return;
    }
    _uploadTask == nil?[self postFileInfo]:[self startExe];
}

/*!
 * 取消/暂停上传
 */
- (void)taskCancel{
    
    _fileStream.fileStatus = CWUploadStatusPaused;
    [self archTaskFileStream];
    _isSuspendedState = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_finishBlock) _finishBlock(_fileStream,nil);
        [self sendNotionWithKey:@"CWUploadTaskExeSuspend" userInfo:@{@"fileStream":_fileStream}];
    });
    if (!_uploadTask) return;
    [self.uploadTask suspend];
    [self.uploadTask cancel];
    self.uploadTask = nil;
}

/*!
 * 释放
 */
- (void)deallocSession{
    _taskRepeatNum = 0;
    self.uploadTask = nil;
    [[NSURLSession sharedSession] finishTasksAndInvalidate];
}

- (void)archTaskFileStream{
    NSMutableDictionary *fsDic = [NRUploadTask unArcherThePlist:plistPath];
    if (!fsDic) {
        fsDic = [NSMutableDictionary dictionary];
    }
    [fsDic setObject:_fileStream forKey:_fileStream.fileName];
    [NRUploadTask archerTheDictionary:fsDic file:plistPath];
}

#pragma mark - 归档反归档
+ (void)archerTheDictionary:(NSDictionary *)dict file:(NSString *)path{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    BOOL finish = [data writeToFile:path atomically:YES];
    if (finish) {};
}

+ (NSMutableDictionary *)unArcherThePlist:(NSString *)path{
    NSMutableDictionary *dic = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    return dic;
}

#pragma mark - 通知
- (void)sendNotionWithKey:(NSString *)key userInfo:(NSDictionary *)dict{
    NSNotification *notification =[NSNotification notificationWithName:key object:nil userInfo:dict];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(NRUploadManager *)uploadManager{
    if (!_uploadManager) {
        _uploadManager = [NRUploadManager shardUploadManager];
    }
    return _uploadManager;
}


- (void)setFileStream:(NRFileStreamConfiguration *)fileStream
{
    _fileStream.fileStatus = CWUploadStatusWaiting;
    _taskRepeatNum = 0;
    _ID = fileStream.md5String;
    for (NSInteger idx=0; idx<fileStream.streamFragments.count; idx++) {
        NRStreamFragment *fragment = fileStream.streamFragments[idx];
        if (!fragment.fragmentStatus) {
            _chunkNo = idx;
        }
    }
    _fileStream = fileStream;
}

@end
