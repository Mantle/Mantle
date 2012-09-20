//
//  MTLValueTransformerSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(MTLValueTransformer)

it(@"should return a forward transformer with a block", ^{
	MTLValueTransformer *transformer = [MTLValueTransformer transformerWithBlock:^(NSString *str) {
		return [str stringByAppendingString:@"bar"];
	}];

	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beFalsy();

	expect([transformer transformedValue:@"foo"]).to.equal(@"foobar");
	expect([transformer transformedValue:@"bar"]).to.equal(@"barbar");
});

it(@"should return a reversible transformer with a block", ^{
	MTLValueTransformer *transformer = [MTLValueTransformer reversibleTransformerWithBlock:^(NSString *str) {
		return [str stringByAppendingString:@"bar"];
	}];

	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beTruthy();

	expect([transformer transformedValue:@"foo"]).to.equal(@"foobar");
	expect([transformer reverseTransformedValue:@"foo"]).to.equal(@"foobar");
});

it(@"should return a reversible transformer with forward and reverse blocks", ^{
	MTLValueTransformer *transformer = [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^(NSString *str) {
			return [str stringByAppendingString:@"bar"];
		}
		reverseBlock:^(NSString *str) {
			return [str substringToIndex:str.length - 3];
		}];

	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beTruthy();

	expect([transformer transformedValue:@"foo"]).to.equal(@"foobar");
	expect([transformer reverseTransformedValue:@"foobar"]).to.equal(@"foo");
});

describe(@"predefined transformers", ^{
	it(@"should define a URL value transformer", ^{
		NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
		expect(transformer).notTo.beNil();

		NSString *URLString = @"http://www.github.com/";
		expect([transformer transformedValue:URLString]).to.equal([NSURL URLWithString:URLString]);
		expect([transformer reverseTransformedValue:[NSURL URLWithString:URLString]]).to.equal(URLString);

		expect([transformer transformedValue:nil]).to.beNil();
		expect([transformer reverseTransformedValue:nil]).to.beNil();
	});
});

SpecEnd
