//
//  MTLTransformerErrorExamples.m
//  Mantle
//
//  Created by Robert Böhnke on 10/9/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Quick/Quick.h>
#import <Nimble/Nimble.h>
#import "MTLTransformerErrorExamples.h"

#import "MTLTransformerErrorHandling.h"

NSString * const MTLTransformerErrorExamples = @"MTLTransformerErrorExamples";

NSString * const MTLTransformerErrorExamplesTransformer = @"MTLTransformerErrorExamplesTransformer";
NSString * const MTLTransformerErrorExamplesInvalidTransformationInput = @"MTLTransformerErrorExamplesInvalidTransformationInput";
NSString * const MTLTransformerErrorExamplesInvalidReverseTransformationInput = @"MTLTransformerErrorExamplesInvalidReverseTransformationInput";

QuickConfigurationBegin(MTLTransformerErrorExamplesConfiguration)

+ (void)configure:(Configuration *)configuration {
	sharedExamples(MTLTransformerErrorExamples, ^(QCKDSLSharedExampleContext data) {
		__block NSValueTransformer<MTLTransformerErrorHandling> *transformer;
		__block id invalidTransformationInput;
		__block id invalidReverseTransformationInput;

		beforeEach(^{
			transformer = data()[MTLTransformerErrorExamplesTransformer];
			invalidTransformationInput = data()[MTLTransformerErrorExamplesInvalidTransformationInput];
			invalidReverseTransformationInput = data()[MTLTransformerErrorExamplesInvalidReverseTransformationInput];

			expect(@([transformer conformsToProtocol:@protocol(MTLTransformerErrorHandling)])).to(beTruthy());
		});

		it(@"should return errors occurring during transformation", ^{
			__block NSError *error;
			__block BOOL success = NO;

			expect([transformer transformedValue:invalidTransformationInput success:&success error:&error]).to(beNil());
			expect(@(success)).to(beFalsy());
			expect(error).notTo(beNil());
			expect(error.domain).to(equal(MTLTransformerErrorHandlingErrorDomain));
			expect(@(error.code)).to(equal(@(MTLTransformerErrorHandlingErrorInvalidInput)));
			expect(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey]).to(equal(invalidTransformationInput));
		});

		it(@"should return errors occurring during reverse transformation", ^{
			if (![transformer.class allowsReverseTransformation]) return;

			__block NSError *error;
			__block BOOL success = NO;

			expect([transformer reverseTransformedValue:invalidReverseTransformationInput success:&success error:&error]).to(beNil());
			expect(@(success)).to(beFalsy());
			expect(error).notTo(beNil());
			expect(error.domain).to(equal(MTLTransformerErrorHandlingErrorDomain));
			expect(@(error.code)).to(equal(@(MTLTransformerErrorHandlingErrorInvalidInput)));
			expect(error.userInfo[MTLTransformerErrorHandlingInputValueErrorKey]).to(equal(invalidReverseTransformationInput));
		});
	});
}

QuickConfigurationEnd
