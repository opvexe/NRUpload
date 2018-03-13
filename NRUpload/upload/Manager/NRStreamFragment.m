//
//  NRStreamFragment.m
//  NRUpload
//
//  Created by Facebook on 2018/3/12.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "NRStreamFragment.h"

@implementation NRStreamFragment

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[self fragmentId] forKey:@"fragmentId"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fragmentSize]] forKey:@"fragmentSize"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fragementOffset]] forKey:@"fragementOffset"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fragmentStatus]] forKey:@"fragmentStatus"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        [self setFragmentId:[aDecoder decodeObjectForKey:@"fragmentId"]];
        [self setFragmentSize:[[aDecoder decodeObjectForKey:@"fragmentSize"] unsignedIntegerValue]];
        [self setFragementOffset:[[aDecoder decodeObjectForKey:@"fragementOffset"] unsignedIntegerValue]];
        [self setFragmentStatus:[[aDecoder decodeObjectForKey:@"fragmentStatus"] boolValue]];
    }
    
    return self;
}
@end
