//
//  MTLParsingOptionsSpec.m
//  Mantle
//
//  Created by Sasha Zats on 2/16/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "MTLTestModel.h"
#import "MTLError.h"

SpecBegin(MTLModelParsingOptionsSpec)

__block NSDictionary *twoInvalidPropertiesDictionary;
__block NSDictionary *oneInvalidPropertyDictionary;
__block MTLTestStructure validTestStructure;
beforeAll(^{
	CGPoint point = (CGPoint){ 20, 20 };
	twoInvalidPropertiesDictionary = @{
		@"structure" : [NSValue value:&point withObjCType:@encode(CGPoint)],
		@"boolean" : @"invalid"
	};
	
	validTestStructure = (MTLTestStructure){ 42, YES };
	oneInvalidPropertyDictionary = @{
		@"structure" : [NSValue value:&validTestStructure withObjCType:@encode(MTLTestStructure)],
		@"boolean" : @"invalid"
	};
});

describe(@"MTLModel", ^{
	it(@"should return an umbrella error and a model when ignore validation error option is specified", ^{
		NSError *error = nil;
		MTLValidationModel *model = [[MTLValidationModel alloc] initWithDictionary:twoInvalidPropertiesDictionary
																		   options:MTLParsingOptionCombineValidationErrors
																			 error:&error];
		expect(model).notTo.beNil();
		expect(error).notTo.beNil();
		expect([error.userInfo[MTLDetailedErrorsKey] count]).to.equal(2);
		expect([error.userInfo[MTLDetailedErrorsKey][0] domain]).to.equal(MTLModelErrorDomain);
		expect([error.userInfo[MTLDetailedErrorsKey][0] code]).to.equal(MTLModelValidationError);
		expect([error.userInfo[MTLDetailedErrorsKey][1] domain]).to.equal(MTLModelErrorDomain);
		expect([error.userInfo[MTLDetailedErrorsKey][1] code]).to.equal(MTLModelValidationError);
	});
	
	it(@"should return one unpacked error and a valid model when ignore validation error option is specified", ^{
		NSError *error = nil;
		MTLValidationModel *model = [[MTLValidationModel alloc] initWithDictionary:oneInvalidPropertyDictionary
																		   options:MTLParsingOptionCombineValidationErrors
																			 error:&error];
		expect(model).notTo.beNil();
		expect(model.structure.count == validTestStructure.count &&
			   model.structure.isOn == validTestStructure.isOn).notTo.beNil();
		expect(error).notTo.beNil();
		expect(error.userInfo[MTLDetailedErrorsKey]).to.beNil();
		expect([error domain]).to.equal(MTLModelErrorDomain);
		expect([error code]).to.equal(MTLModelValidationError);
	});
	
	it(@"should fail on the first validation error when ignore validation error option is not specified", ^{
		NSError *error = nil;
		MTLValidationModel *model = [[MTLValidationModel alloc] initWithDictionary:twoInvalidPropertiesDictionary
																		   options:0
																			 error:&error];
		expect(model).to.beNil();
		expect(error).notTo.beNil();
		expect([error domain]).to.equal(MTLModelErrorDomain);
		expect([error code]).to.equal(MTLModelValidationError);
	});
});

describe(@"MTLJSONAdapter", ^{
	it(@"should return an umbrella error errors when ignore validation error option is specified", ^{
		NSError *error = nil;

		MTLValidationModel *model = [MTLJSONAdapter modelOfClass:MTLValidationModel.class
											  fromJSONDictionary:twoInvalidPropertiesDictionary
														 options:MTLParsingOptionCombineValidationErrors
														   error:&error];
		expect(model).notTo.beNil();
		expect(error).notTo.beNil();
		expect([error.userInfo[MTLDetailedErrorsKey] count]).to.equal(2);
		expect([error.userInfo[MTLDetailedErrorsKey][0] domain]).to.equal(MTLModelErrorDomain);
		expect([error.userInfo[MTLDetailedErrorsKey][0] code]).to.equal(MTLModelValidationError);
		expect([error.userInfo[MTLDetailedErrorsKey][1] domain]).to.equal(MTLModelErrorDomain);
		expect([error.userInfo[MTLDetailedErrorsKey][1] code]).to.equal(MTLModelValidationError);
	});
	
	it(@"should return one unpacked error and a valid model when ignore validation error option is specified", ^{
		NSError *error = nil;
		MTLValidationModel *model = [MTLJSONAdapter modelOfClass:MTLValidationModel.class
											  fromJSONDictionary:oneInvalidPropertyDictionary
														 options:MTLParsingOptionCombineValidationErrors
														   error:&error];
		expect(model).notTo.beNil();
		expect(model.structure.count == validTestStructure.count &&
			   model.structure.isOn == validTestStructure.isOn).notTo.beNil();
		expect(error).notTo.beNil();
		expect(error.userInfo[MTLDetailedErrorsKey]).to.beNil();
		expect([error domain]).to.equal(MTLModelErrorDomain);
		expect([error code]).to.equal(MTLModelValidationError);
	});

	
	it(@"should fail on the first validation error when ignore validation error option is not specified", ^{
		NSError *error = nil;
		MTLValidationModel *model = [MTLJSONAdapter modelOfClass:MTLValidationModel.class
											  fromJSONDictionary:twoInvalidPropertiesDictionary
														 options:0
														   error:&error];
		expect(model).to.beNil();
		expect(error).notTo.beNil();
		expect([error domain]).to.equal(MTLModelErrorDomain);
		expect([error code]).to.equal(MTLModelValidationError);
	});
});

SpecEnd