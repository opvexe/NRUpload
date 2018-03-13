//
//  NRFileStreamConfiguration.h
//  NRUpload
//
//  Created by Facebook on 2018/3/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define NRStreamFragmentMaxSize         1024 *512 // 500KB 最大上传大小

typedef enum : NSUInteger {
    CWUploadStatusWaiting = 0,//任务队列等待
    CWUploadStatusUpdownloading,//上传中
    CWUploadStatusPaused,//暂停
    CWUploadStatusFinished,//上传成功
    CWUploadStatusFailed //上传失败
} CWUploadStatus;//任务状态


@class NRStreamFragment;
@interface NRFileStreamConfiguration : NSObject<NSCopying>

#pragma mark - 文件流相关
//包括文件后缀名的文件名
@property (nonatomic,copy,readonly)NSString *fileName;
//文件大小
@property (nonatomic,assign,readonly)NSUInteger fileSize;
//文件所在的文件目录
@property (nonatomic,copy) NSString *filePath;
//文件状态
@property (nonatomic,assign)CWUploadStatus fileStatus;
//文件md5
@property (nonatomic,copy) NSString *md5String;
//文件分片流数组
@property(nonatomic,strong)NSArray<NRStreamFragment*> *streamFragments;
//上传进度
@property (nonatomic,assign,readonly) double progressRate;
//已上传文件大小
@property (nonatomic,assign,readonly) NSInteger uploadDateSize;
//片的唯一标识
@property (nonatomic,copy) NSString *bizId;

#pragma mark - 文件操作
/*!
 * 读取或写入文件数据
 */
-(instancetype)initFileOperationAtPath:(NSString*)path forReadOperation:(BOOL)isReadOperation;

/*!
 * 获取当前偏移量
 */
- (NSUInteger)offsetInFile;
/*!
 * 设置偏移量, 仅对读取设置
 */
- (void)seekToFileOffset:(NSUInteger)offset;
/*!
 * 关闭文件
 */
- (void)closeFile;

#pragma mark - 读操作

/*!
 * 通过分片信息读取对应的片数据
 */
- (NSData*)readDateOfFragment:(NRStreamFragment*)fragment;
/*!
 * 从当前文件偏移量开始
 */
- (NSData*)readDataOfLength:(NSUInteger)bytes;
/*!
 * 从当前文件偏移量开始
 */
- (NSData*)readDataToEndOfFile;
/*!
 * 从当前文件偏移量末尾
 */
- (NSUInteger)seekToEndOfFile;

#pragma mark - 写操作
/*!
 * 写入文件数据
 */
- (void)writeData:(NSData *)data;

@end
