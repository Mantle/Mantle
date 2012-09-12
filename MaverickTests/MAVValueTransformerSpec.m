//
//  MAVValueTransformerSpec.m
//  Maverick
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

SpecBegin(MAVValueTransformer)

it(@"should return a forward transformer with a block", ^{
	MAVValueTransformer *transformer = [MAVValueTransformer transformerWithBlock:^(NSString *str){
		return [str stringByAppendingString:@"bar"];
	}];

	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beFalsy();

	expect([transformer transformedValue:@"foo"]).to.equal(@"foobar");
	expect([transformer transformedValue:@"bar"]).to.equal(@"barbar");
});

it(@"should return a reversible transformer with a block", ^{
	MAVValueTransformer *transformer = [MAVValueTransformer reversibleTransformerWithBlock:^(NSString *str){
		return [str stringByAppendingString:@"bar"];
	}];

	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beTruthy();

	expect([transformer transformedValue:@"foo"]).to.equal(@"foobar");
	expect([transformer reverseTransformedValue:@"foo"]).to.equal(@"foobar");
});

it(@"should return a reversible transformer with forward and reverse blocks", ^{
	MAVValueTransformer *transformer = [MAVValueTransformer
		reversibleTransformerWithForwardBlock:^(NSString *str){
			return [str stringByAppendingString:@"bar"];
		}
		reverseBlock:^(NSString *str){
			return [str substringToIndex:str.length - 3];
		}];

	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beTruthy();

	expect([transformer transformedValue:@"foo"]).to.equal(@"foobar");
	expect([transformer reverseTransformedValue:@"foobar"]).to.equal(@"foo");
});

SpecEnd
