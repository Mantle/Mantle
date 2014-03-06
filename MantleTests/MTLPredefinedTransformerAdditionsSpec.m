//
//  MTLPredefinedTransformerAdditionsSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTransformerErrorExamples.h"

#import "MTLTestModel.h"

enum : NSInteger {
	MTLPredefinedTransformerAdditionsSpecEnumNegative = -1,
	MTLPredefinedTransformerAdditionsSpecEnumZero = 0,
	MTLPredefinedTransformerAdditionsSpecEnumPositive = 1,
} MTLPredefinedTransformerAdditionsSpecEnum;

SpecBegin(MTLPredefinedTransformerAdditions)

describe(@"The URL transformer", ^{
	__block NSValueTransformer *transformer;

	beforeEach(^{
		transformer = [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];

		expect(transformer).notTo.beNil();
		expect([transformer.class allowsReverseTransformation]).to.beTruthy();
	});

	it(@"should convert NSStrings to NSURLs and back", ^{
		NSString *URLString = @"http://www.github.com/";
		expect([transformer transformedValue:URLString]).to.equal([NSURL URLWithString:URLString]);
		expect([transformer reverseTransformedValue:[NSURL URLWithString:URLString]]).to.equal(URLString);

		expect([transformer transformedValue:nil]).to.beNil();
		expect([transformer reverseTransformedValue:nil]).to.beNil();
	});

	itShouldBehaveLike(MTLTransformerErrorExamples, ^{
		return @{
			MTLTransformerErrorExamplesTransformer: transformer,
			MTLTransformerErrorExamplesInvalidTransformationInput: @"not a valid URL",
			MTLTransformerErrorExamplesInvalidReverseTransformationInput: NSNull.null
		};
	});
});

describe(@"The number transformer", ^{
	__block NSValueTransformer *transformer;

	beforeEach(^{
		transformer = [NSValueTransformer valueTransformerForName:MTLBooleanValueTransformerName];
		expect(transformer).notTo.beNil();
		expect([transformer.class allowsReverseTransformation]).to.beTruthy();
	});

	it(@"it convert int- to boolean-backed NSNumbers and back", ^{
		// Back these NSNumbers with ints, rather than booleans,
		// to ensure that the value transformers are actually transforming.
		NSNumber *booleanYES = @(1);
		NSNumber *booleanNO = @(0);

		expect([transformer transformedValue:booleanYES]).to.equal([NSNumber numberWithBool:YES]);
		expect([transformer transformedValue:booleanYES]).to.beIdenticalTo((id)kCFBooleanTrue);

		expect([transformer reverseTransformedValue:booleanYES]).to.equal([NSNumber numberWithBool:YES]);
		expect([transformer reverseTransformedValue:booleanYES]).to.beIdenticalTo((id)kCFBooleanTrue);

		expect([transformer transformedValue:booleanNO]).to.equal([NSNumber numberWithBool:NO]);
		expect([transformer transformedValue:booleanNO]).to.beIdenticalTo((id)kCFBooleanFalse);

		expect([transformer reverseTransformedValue:booleanNO]).to.equal([NSNumber numberWithBool:NO]);
		expect([transformer reverseTransformedValue:booleanNO]).to.beIdenticalTo((id)kCFBooleanFalse);

		expect([transformer transformedValue:nil]).to.beNil();
		expect([transformer reverseTransformedValue:nil]).to.beNil();
	});

	itShouldBehaveLike(MTLTransformerErrorExamples, ^{
		return @{
			MTLTransformerErrorExamplesTransformer: transformer,
			MTLTransformerErrorExamplesInvalidTransformationInput: NSNull.null,
			MTLTransformerErrorExamplesInvalidReverseTransformationInput: NSNull.null
		};
	});
});

describe(@"value mapping transformer", ^{
	__block NSValueTransformer *transformer;

	NSDictionary *dictionary = @{
		@"negative": @(MTLPredefinedTransformerAdditionsSpecEnumNegative),
		@[ @"zero" ]: @(MTLPredefinedTransformerAdditionsSpecEnumZero),
		@"positive": @(MTLPredefinedTransformerAdditionsSpecEnumPositive),
	};

	beforeEach(^{
		transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:dictionary];
	});

	it(@"should transform enum values into strings", ^{
		expect([transformer transformedValue:@"negative"]).to.equal(@(MTLPredefinedTransformerAdditionsSpecEnumNegative));
		expect([transformer transformedValue:@[ @"zero" ]]).to.equal(@(MTLPredefinedTransformerAdditionsSpecEnumZero));
		expect([transformer transformedValue:@"positive"]).to.equal(@(MTLPredefinedTransformerAdditionsSpecEnumPositive));
	});

	it(@"should transform strings into enum values", ^{
		expect([transformer.class allowsReverseTransformation]).to.beTruthy();

		expect([transformer reverseTransformedValue:@(MTLPredefinedTransformerAdditionsSpecEnumNegative)]).to.equal(@"negative");
		expect([transformer reverseTransformedValue:@(MTLPredefinedTransformerAdditionsSpecEnumZero)]).to.equal(@[ @"zero" ]);
		expect([transformer reverseTransformedValue:@(MTLPredefinedTransformerAdditionsSpecEnumPositive)]).to.equal(@"positive");
	});
});

SpecEnd
