//
//  NSValueTransformer+MTLInversionAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-05-18.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "NSValueTransformer+MTLInversionAdditions.h"
#import "MTLValueTransformer.h"

@implementation NSValueTransformer (MTLInversionAdditions)

- (NSValueTransformer *)mtl_invertedTransformer {
	NSParameterAssert(self.class.allowsReverseTransformation);

	return [MTLValueTransformer reversibleTransformerWithForwardTransformation:^(id value, BOOL *success, NSError **error) {
		return [self reverseTransformedValue:value];
	} reverseTransformation:^(id value, BOOL *success, NSError **error) {
		return [self transformedValue:value];
	}];
}

@end
