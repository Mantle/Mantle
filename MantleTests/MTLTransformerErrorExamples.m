//
//  MTLTransformerErrorExamples.m
//  Mantle
//
//  Created by Robert Böhnke on 10/9/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTransformerErrorExamples.h"

#import "MTLTransformerErrorHandling.h"

NSString * const MTLTransformerErrorExamples = @"MTLTransformerErrorExamples";

NSString * const MTLTransformerErrorExamplesTransformer = @"MTLTransformerErrorExamplesTransformer";
NSString * const MTLTransformerErrorExamplesInvalidTransformationInput = @"MTLTransformerErrorExamplesInvalidTransformationInput";
NSString * const MTLTransformerErrorExamplesInvalidReverseTransformationInput = @"MTLTransformerErrorExamplesInvalidReverseTransformationInput";

SharedExampleGroupsBegin(MTLTransformerErrorExamples);

sharedExamplesFor(MTLTransformerErrorExamples, ^(NSDictionary *data) {
	__block NSValueTransformer<MTLTransformerErrorHandling> *transformer;
	__block id invalidTransformationInput;
	__block id invalidReverseTransformationInput;

	beforeEach(^{
		transformer = data[MTLTransformerErrorExamplesTransformer];
		invalidTransformationInput = data[MTLTransformerErrorExamplesInvalidTransformationInput];
		invalidReverseTransformationInput = data[MTLTransformerErrorExamplesInvalidReverseTransformationInput];

		expect([transformer conformsToProtocol:@protocol(MTLTransformerErrorHandling)]).to.beTruthy();
	});

	it(@"should return errors occurring during transformation", ^{
		__block NSError *error;
		__block BOOL success;

		expect([transformer transformedValue:invalidTransformationInput success:&success error:&error]).to.beNil();
		expect(success).to.beFalsy();
		expect(error).notTo.beNil();
	});

	it(@"should return errors occurring during reverse transformation", ^{
		if (![transformer.class allowsReverseTransformation]) return;

		__block NSError *error;
		__block BOOL success;

		expect([transformer reverseTransformedValue:invalidReverseTransformationInput success:&success error:&error]).to.beNil();
		expect(success).to.beFalsy();
		expect(error).notTo.beNil();
	});
});

SharedExampleGroupsEnd
