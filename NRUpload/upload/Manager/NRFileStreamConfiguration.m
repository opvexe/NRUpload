//
//  NRFileStreamConfiguration.m
//  NRUpload
//
//  Created by Facebook on 2018/3/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "NRFileStreamConfiguration.h"
#import "NRStreamFragment.h"
#import "NRFileManager.h"
#import "NSString+md5.h"

@interface NRFileStreamConfiguration()
@property (nonatomic,copy) NSString                          *fileName;
@property (nonatomic,assign) NSUInteger                      fileSize;
@property (nonatomic,strong) NSFileHandle                    *readFileHandle;
@property (nonatomic,strong) NSFileHandle                    *writeFileHandle;
@property (nonatomic,assign) BOOL                            isReadOperation;
@property (nonatomic,assign) double progressRate;
@property (nonatomic,assign) NSInteger uploadDateSize;
@end
@implementation NRFileStreamConfiguration

#pragma mark - NSCopying

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[self fileName] forKey:@"fileName"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fileSize]] forKey:@"fileSize"];
    [aCoder encodeObject:[NSNumber numberWithInteger:[self fileStatus]] forKey:@"fileStatus"];
    [aCoder encodeObject:[self filePath] forKey:@"filePath"];
    [aCoder encodeObject:[self md5String] forKey:@"md5String"];
    [aCoder encodeObject:[self streamFragments] forKey:@"streamFragments"];
    [aCoder encodeObject:[self bizId] forKey:@"bizId"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self uploadDateSize]] forKey:@"uploadDateSize"];
    [aCoder encodeObject:[NSNumber numberWithDouble:[self progressRate]] forKey:@"progressRate"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        [self setFileName:[aDecoder decodeObjectForKey:@"fileName"]];
        [self setFileStatus:[[aDecoder decodeObjectForKey:@"fileStatus"] intValue]];
        [self setFileSize:[[aDecoder decodeObjectForKey:@"fileSize"] unsignedIntegerValue]];
        [self setFilePath:[aDecoder decodeObjectForKey:@"filePath"]];
        [self setMd5String:[aDecoder decodeObjectForKey:@"md5String"]];
        [self setStreamFragments:[aDecoder decodeObjectForKey:@"streamFragments"]];
        [self setBizId:[aDecoder decodeObjectForKey:@"bizId"]];
        [self setProgressRate:[[aDecoder decodeObjectForKey:@"progressRate"] doubleValue]];
        [self setUploadDateSize:[[aDecoder decodeObjectForKey:@"uploadDateSize"] unsignedIntegerValue]];
    }
    return self;
}

#pragma mark -

-(void)setFileStatus:(CWUploadStatus)fileStatus{
    _fileStatus = fileStatus;
    for (NSInteger num=0; num <self.streamFragments.count;num ++ ) {
        NRStreamFragment *ftp = _streamFragments[num];
        if (num == _streamFragments.count -1&&!ftp.fragmentStatus) {
            _progressRate = (num + 1.0)/_streamFragments.count;
            _uploadDateSize = self.fileSize;
            break;
        }
        if (!ftp.fragmentStatus) {  ///上传失败
            _progressRate = (num + 1.0)/_streamFragments.count;
            _uploadDateSize = NRStreamFragmentMaxSize * (num + 1.0);
            break;
        }
    }
}

#pragma mark -
/*!
 * 读取或写入文件数据
 */
-(instancetype)initFileOperationAtPath:(NSString*)path forReadOperation:(BOOL)isReadOperation{
    
    if (self =[super init]) {
        self.isReadOperation = isReadOperation;
        if (_isReadOperation) {     ///读
            if (![self getFileInfoAtPath:path]) {
                return nil;
            }
            self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
            [self cutFileForFragments];
            
        }else{       //写
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            if (![fileMgr fileExistsAtPath:path]) {
                [fileMgr createFileAtPath:path contents:nil attributes:nil];
            }
            if (![self getFileInfoAtPath:path]) {
                return nil;
            }
            self.writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        }
    }
    return self;
}

/*!
 * 切片上传文件
 */
-(void)cutFileForFragments{
    
     NSUInteger offset = NRStreamFragmentMaxSize;
     NSUInteger chunks = (_fileSize%offset==0)?(_fileSize/offset):(_fileSize/(offset) + 1);     //上传 几块
     NSMutableArray<NRStreamFragment *> *fragments = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSUInteger i = 0 ; i < chunks; i ++) {
        
        NRStreamFragment *ftp = [[NRStreamFragment alloc] init];
        ftp.fragmentStatus = NO;
        ftp.fragmentId = [[self class] fileKey];
        ftp.fragementOffset = i * offset;
        
        if (i != chunks - 1) {
            ftp.fragmentSize = offset ;
        }else{  //最后一块
            ftp.fragmentSize = _fileSize - ftp.fragementOffset;
        }
        [fragments addObject:ftp];
    }
    self.streamFragments =  [NSArray arrayWithArray:fragments];
}

/*!
 * 获取当前偏移量
 */
- (NSUInteger)offsetInFile{
    
    if (_isReadOperation) {
        return [_readFileHandle offsetInFile];
    }
    
    return [_writeFileHandle offsetInFile];
}
/*!
 * 设置偏移量, 仅对读取设置
 */
- (void)seekToFileOffset:(NSUInteger)offset{
    
      [_readFileHandle seekToFileOffset:offset];
}


/*!
 * 关闭文件
 */
- (void)closeFile{
    
    if (_isReadOperation) {
        [_readFileHandle closeFile];
    } else {
        [_writeFileHandle closeFile];
    }
}

#pragma mark - 读操作

/*!
 * 通过分片信息读取对应的片数据
 */
- (NSData*)readDateOfFragment:(NRStreamFragment*)fragment{
    
    if (self.readFileHandle==nil) {
        self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:_filePath];
    }
    
    if (fragment) {
        [self seekToFileOffset:fragment.fragementOffset];
        return [_readFileHandle readDataOfLength:fragment.fragmentSize];
    }
    [self closeFile];
    return nil;
}

/*!
 * 从当前文件偏移量开始
 */
- (NSData*)readDataOfLength:(NSUInteger)bytes{
    
      return [_readFileHandle readDataOfLength:bytes];
}
/*!
 * 从当前文件偏移量开始
 */
- (NSData*)readDataToEndOfFile{
    
     return [_readFileHandle readDataToEndOfFile];
}

/*!
 * 从当前文件偏移量末尾
 */
- (NSUInteger)seekToEndOfFile{
    
    if (_isReadOperation) {
        return (NSUInteger)[_readFileHandle seekToEndOfFile];
    }
    return [_writeFileHandle seekToEndOfFile];
}

#pragma mark - 写操作
/*!
 * 写入文件数据
 */
- (void)writeData:(NSData *)data{
    
    [_writeFileHandle writeData:data];
}

#pragma mark - 创建文件（无文件时创建）
- (BOOL)getFileInfoAtPath:(NSString*)path {
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:path]) {
        NSLog(@"文件不存在：%@",path);
        return NO;
    }
    self.filePath = path;
    NSDictionary *attr =[fileMgr attributesOfItemAtPath:path error:nil];
    self.fileSize = attr.fileSize;
    
    self.md5String = [NSString fileKeyMD5WithPath:path];
    
    self.bizId=[[NSUUID UUID] UUIDString];
    
    self.uploadDateSize = 0;
    self.progressRate = 0.00;
    
    NSString *fileName = [path lastPathComponent];
    self.fileName = fileName;
    
    self.fileStatus = CWUploadStatusWaiting;
    
    return YES;
}

@end

