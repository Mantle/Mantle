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

it(@"should define an NSNumber boolean value transformer", ^{
	NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
	expect(transformer).notTo.beNil();
	expect([transformer.class allowsReverseTransformation]).to.beTruthy();

	NSNumber *booleanYES = @(1);
	expect([transformer transformedValue:booleanYES]).to.equal([NSNumber numberWithBOOL:YES]);
	expect([[transformer transformedValue:booleanYES] class]).to.equal(@"__NSCFBoolean");
	expect([transformer reverseTransformedValue:booleanYES]).to.equal([NSNumber numberWithBOOL:YES]);
	expect([[[transformer reverseTransformedValue:booleanYES] class] description]).to.equal(@"__NSCFBoolean");

	NSNumber *booleanNO = @(0);
	expect([transformer transformedValue:booleanNO]).to.equal([NSNumber numberWithBOOL:NO]);
	expect([[transformer transformedValue:booleanNO] class]).to.equal(@"__NSCFBoolean");
	expect([transformer reverseTransformedValue:booleanNO]).to.equal([NSNumber numberWithBOOL:NO]);
	expect([[[transformer reverseTransformedValue:booleanNO] class] description]).to.equal(@"__NSCFBoolean");

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

describe(@"external representation array transformer", ^{
	__block NSArray *models;
	__block NSArray *externalRepresentations;
	__block NSValueTransformer *transformer;

	before(^{
		NSMutableArray *uniqueModels = [NSMutableArray array];
		for (NSUInteger i = 0; i < 10; i++) {
			MTLTestModel *model = [[MTLTestModel alloc] init];
			model.count = i;

			[uniqueModels addObject:model];
		}

		models = [uniqueModels copy];
		externalRepresentations = [uniqueModels mtl_mapUsingBlock:^(MTLTestModel *model) {
			return model.externalRepresentation;
		}];

		expect(models).notTo.beNil();
		expect(externalRepresentations).notTo.beNil();

		transformer = [NSValueTransformer mtl_externalRepresentationArrayTransformerWithModelClass:MTLTestModel.class];
		expect(transformer).notTo.beNil();
	});

	it(@"should transform external representations into models", ^{
		expect([transformer transformedValue:externalRepresentations]).to.equal(models);
	});

	it(@"should transform models into external representations", ^{
		expect([transformer.class allowsReverseTransformation]).to.beTruthy();
		expect([transformer reverseTransformedValue:models]).to.equal(externalRepresentations);
	});
});

SpecEnd
