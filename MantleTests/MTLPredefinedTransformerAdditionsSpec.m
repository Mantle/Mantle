//
//  MTLPredefinedTransformerAdditionsSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

SpecBegin(MTLPredefinedTransformerAdditions)

it(@"should define a URL value transformer", ^{
	NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beTruthy();

	NSString *URLString = @"http://www.github.com/";
	expect([transformer transformedValue:URLString]).to.equal([NSURL URLWithString:URLString]);
	expect([transformer reverseTransformedValue:[NSURL URLWithString:URLString]]).to.equal(URLString);

	expect([transformer transformedValue:nil]).to.beNil();
	expect([transformer reverseTransformedValue:nil]).to.beNil();
});

describe(@"external representation transformer", ^{
	__block MTLTestModel *model;
	__block NSValueTransformer *transformer;

	before(^{
		model = [[MTLTestModel alloc] init];
		expect(model).notTo.beNil();

		transformer = [NSValueTransformer mtl_externalRepresentationTransformerWithModelClass:model.class];
		expect(transformer).notTo.beNil();
	});

	it(@"should transform an external representation into a model", ^{
		expect([transformer transformedValue:model.externalRepresentation]).to.equal(model);
	});

	it(@"should transform a model into an external representation", ^{
		expect([transformer.class allowsReverseTransformation]).to.beTruthy();
		expect([transformer reverseTransformedValue:model]).to.equal(model.externalRepresentation);
	});
});

SpecEnd
