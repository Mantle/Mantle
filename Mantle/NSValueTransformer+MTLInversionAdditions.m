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

	return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(id value) {
		return [self reverseTransformedValue:value];
	} reverseBlock:^(id value) {
		return [self transformedValue:value];
	}];
}

@end
