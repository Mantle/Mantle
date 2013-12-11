//
//  MTLTestJSONAdapter.m
//  Mantle
//
//  Created by Robert Böhnke on 11/12/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestJSONAdapter.h"

@implementation MTLTestJSONAdapter

- (NSValueTransformer *)valueTransformerForObjcType:(const char *)objcType {
	if (strcmp(objcType, @encode(long)) == 0) {
		return [MTLValueTransformer
			transformerUsingForwardBlock:^(NSString *string, BOOL *success, NSError *__autoreleasing *error) {
				return [NSNumber numberWithLong:string.longLongValue];
			}
			reverseBlock:^(NSNumber *number, BOOL *success, NSError *__autoreleasing *error) {
				return [NSString stringWithFormat:@"%ld", number.longValue];
			}];
	} else {
		return [super valueTransformerForObjcType:objcType];
	}
}

@end
