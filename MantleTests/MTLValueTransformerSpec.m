//
//  MTLValueTransformerSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(MTLValueTransformer)

it(@"should return a forward transformer with a block", ^{
	MTLValueTransformer *transformer = [MTLValueTransformer transformerWithTransformation:^(NSString *str, NSError **error) {
		return [str stringByAppendingString:@"bar"];
	}];

	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beFalsy();

	expect([transformer transformedValue:@"foo"]).to.equal(@"foobar");
	expect([transformer transformedValue:@"bar"]).to.equal(@"barbar");
});

it(@"should return a reversible transformer with a block", ^{
	MTLValueTransformer *transformer = [MTLValueTransformer reversibleTransformerWithTransformation:^(NSString *str, NSError **error) {
		return [str stringByAppendingString:@"bar"];
	}];

	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beTruthy();

	expect([transformer transformedValue:@"foo"]).to.equal(@"foobar");
	expect([transformer reverseTransformedValue:@"foo"]).to.equal(@"foobar");
});

it(@"should return a reversible transformer with forward and reverse blocks", ^{
	MTLValueTransformer *transformer = [MTLValueTransformer
		reversibleTransformerWithForwardTransformation:^(NSString *str, NSError **error) {
			return [str stringByAppendingString:@"bar"];
		}
		reverseTransformation:^(NSString *str, NSError **error) {
			return [str substringToIndex:str.length - 3];
		}];

	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beTruthy();

	expect([transformer transformedValue:@"foo"]).to.equal(@"foobar");
	expect([transformer reverseTransformedValue:@"foobar"]).to.equal(@"foo");
});

SpecEnd
