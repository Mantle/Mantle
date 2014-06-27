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
	MTLPredefinedTransformerAdditionsSpecEnumDefault = 42,
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


describe(@"JSON transformers", ^{
	describe(@"dictionary transformer", ^{
		__block NSValueTransformer *transformer;

		__block MTLTestModel *model;
		__block NSDictionary *JSONDictionary;

		before(^{
			model = [[MTLTestModel alloc] init];
			JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model error:NULL];

			transformer = [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:MTLTestModel.class];
			expect(transformer).notTo.beNil();
		});

		it(@"should transform a JSON dictionary into a model", ^{
			expect([transformer transformedValue:JSONDictionary]).to.equal(model);
		});

		it(@"should transform a model into a JSON dictionary", ^{
			expect([transformer.class allowsReverseTransformation]).to.beTruthy();
			expect([transformer reverseTransformedValue:model]).to.equal(JSONDictionary);
		});

		itShouldBehaveLike(MTLTransformerErrorExamples, ^{
			return @{
				MTLTransformerErrorExamplesTransformer: transformer,
				MTLTransformerErrorExamplesInvalidTransformationInput: NSNull.null,
				MTLTransformerErrorExamplesInvalidReverseTransformationInput: NSNull.null
			};
		});
	});

	describe(@"external representation array transformer", ^{
		__block NSValueTransformer *transformer;

		__block NSArray *models;
		__block NSArray *JSONDictionaries;

		beforeEach(^{
			NSMutableArray *uniqueModels = [NSMutableArray array];
			NSMutableArray *mutableDictionaries = [NSMutableArray array];

			for (NSUInteger i = 0; i < 10; i++) {
				MTLTestModel *model = [[MTLTestModel alloc] init];
				model.count = i;

				[uniqueModels addObject:model];

				NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:model error:NULL];
				expect(dict).notTo.beNil();

				[mutableDictionaries addObject:dict];
			}

			uniqueModels[2] = NSNull.null;
			mutableDictionaries[2] = NSNull.null;

			models = [uniqueModels copy];
			JSONDictionaries = [mutableDictionaries copy];

			transformer = [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:MTLTestModel.class];
			expect(transformer).notTo.beNil();
		});

		it(@"should transform JSON dictionaries into models", ^{
			expect([transformer transformedValue:JSONDictionaries]).to.equal(models);
		});

		it(@"should transform models into JSON dictionaries", ^{
			expect([transformer.class allowsReverseTransformation]).to.beTruthy();
			expect([transformer reverseTransformedValue:models]).to.equal(JSONDictionaries);
		});

		itShouldBehaveLike(MTLTransformerErrorExamples, ^{
			return @{
				MTLTransformerErrorExamplesTransformer: transformer,
				MTLTransformerErrorExamplesInvalidTransformationInput: NSNull.null,
				MTLTransformerErrorExamplesInvalidReverseTransformationInput: NSNull.null
			};
		});
	});
});

describe(@"+mtl_arrayMappingTransformerWithTransformer:", ^{
	__block NSValueTransformer *transformer;
	
	NSArray *URLStrings = @[
		@"https://github.com/",
		@"https://github.com/MantleFramework",
		@"http://apple.com"
	];
	NSArray *URLs = @[
		[NSURL URLWithString:@"https://github.com/"],
		[NSURL URLWithString:@"https://github.com/MantleFramework"],
		[NSURL URLWithString:@"http://apple.com"]
	];
	
	describe(@"when called with a reversible transformer", ^{
		beforeEach(^{
			NSValueTransformer *appliedTransformer = [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
			transformer = [NSValueTransformer mtl_arrayMappingTransformerWithTransformer:appliedTransformer];
			expect(transformer).notTo.beNil();
		});
		
		it(@"should allow reverse transformation", ^{
			expect([transformer.class allowsReverseTransformation]).to.beTruthy();
		});
		
		it(@"should apply the transformer to each element", ^{
			expect([transformer transformedValue:URLStrings]).to.equal(URLs);
		});
		
		it(@"should apply the transformer to each element in reverse", ^{
			expect([transformer reverseTransformedValue:URLs]).to.equal(URLStrings);
		});
	});
	
	describe(@"when called with a non-reversible transformer", ^{
		beforeEach(^{
			NSValueTransformer *appliedTransformer = [MTLValueTransformer transformerUsingForwardBlock:^(NSString *str, BOOL *success, NSError **error) {
				return [NSURL URLWithString:str];
			}];
			transformer = [NSValueTransformer mtl_arrayMappingTransformerWithTransformer:appliedTransformer];
			expect(transformer).notTo.beNil();
		});
		
		it(@"should not allow reverse transformation", ^{
			expect([transformer.class allowsReverseTransformation]).to.beFalsy();
		});
		
		it(@"should apply the transformer to each element", ^{
			expect([transformer transformedValue:URLStrings]).to.equal(URLs);
		});
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

	describe(@"default values", ^{
		beforeEach(^{
			transformer = [NSValueTransformer mtl_valueMappingTransformerWithDictionary:dictionary defaultValue:@(MTLPredefinedTransformerAdditionsSpecEnumDefault) reverseDefaultValue:@"default"];
		});

		it(@"should transform unknown strings into the default enum value", ^{
			expect([transformer transformedValue:@"unknown"]).to.equal(@(MTLPredefinedTransformerAdditionsSpecEnumDefault));
		});

		it(@"should transform the default enum value into the default string", ^{
			expect([transformer reverseTransformedValue:@(MTLPredefinedTransformerAdditionsSpecEnumDefault)]).to.equal(@"default");
		});
	});
});

SpecEnd
