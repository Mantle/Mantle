//
//  NSValueTransformer+MTLInversionAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-05-18.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "NSValueTransformer+MTLInversionAdditions.h"
#import "MTLTransformerErrorHandling.h"
#import "MTLValueTransformer.h"

@implementation NSValueTransformer (MTLInversionAdditions)

- (NSValueTransformer *)mtl_invertedTransformer {
	NSParameterAssert(self.class.allowsReverseTransformation);

	if ([self conformsToProtocol:@protocol(MTLTransformerErrorHandling)]) {
		NSParameterAssert([self respondsToSelector:@selector(reverseTransformedValue:success:error:)]);

		return [MTLValueTransformer reversibleTransformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
			return [(id) self reverseTransformedValue:value success:success error:error];
		} reverseBlock:^(id value, BOOL *success, NSError **error) {
			return [(id) self transformedValue:value success:success error:error];
		}];
	} else {
		return [MTLValueTransformer reversibleTransformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
			return [self reverseTransformedValue:value];
		} reverseBlock:^(id value, BOOL *success, NSError **error) {
			return [self transformedValue:value];
		}];
	}
}

@end
