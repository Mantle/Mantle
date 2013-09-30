//
//  MTLValueTransformerErrorHandlingSpec.m
//  Mantle
//
//  Created by Robert Böhnke on 10/1/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLValueTransformer.h"

#import "NSValueTransformer+MTLErrorHandling.h"

SpecBegin(MTLValueTransformerErrorHandling)

__block NSValueTransformer *transformer;

beforeEach(^{
	transformer = [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^NSString *(id value) {
			if ([value isKindOfClass:NSString.class]) {
				return [value uppercaseString];
			} else {
				return nil;
			}
		}
		reverseBlock:^NSString *(id value) {
			if ([value isKindOfClass:NSString.class]) {
				return [value lowercaseString];
			} else {
				return nil;
			}
		}];
});

describe(@"-mtl_transformedValue:error:", ^{
	it(@"should invoke -transformedValue:", ^{
		__block NSError *error;
		expect([transformer mtl_transformedValue:@"foo" error:&error]).to.equal(@"FOO");

		expect(error).to.beNil();
	});

	it(@"should return a default error if transformation fails", ^{
		__block NSError *error;
		expect([transformer mtl_transformedValue:@1 error:&error]).to.beNil();

		expect(error).notTo.beNil();
		expect(error.domain).to.equal(MTLValueTransformerErrorDomain);
		expect(error.code).to.equal(MTLValueTransformerErrorTransformationFailed);
	});
});

describe(@"-mtl_reverseTransformedValue:error:", ^{
	it(@"should invoke -reverseTransformedValue:", ^{
		__block NSError *error;
		expect([transformer mtl_reverseTransformedValue:@"FOO" error:&error]).to.equal(@"foo");

		expect(error).to.beNil();
	});

	it(@"should return a default error if transformation fails", ^{
		__block NSError *error;
		expect([transformer mtl_reverseTransformedValue:@1 error:&error]).to.beNil();

		expect(error).notTo.beNil();
		expect(error.domain).to.equal(MTLValueTransformerErrorDomain);
		expect(error.code).to.equal(MTLValueTransformerErrorTransformationFailed);
	});
});

SpecEnd
