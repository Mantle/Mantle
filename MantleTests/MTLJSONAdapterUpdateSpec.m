//
//  MTLJSONAdapterUpdateSpec.m
//  Mantle
//
//  Created by Christian Bianciotto on 2014-05-09.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

SpecBegin(MTLJSONAdapterUpdate)

it(@"should initialize from a model and JSON on update", ^{
	NSDictionary *values = @{
		@"username": NSNull.null,
		@"count": @"5",
	};
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];
	
	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:values model:model error:&error];
	expect(adapter).notTo.beNil();
	expect(error).to.beNil();
	
	expect(model.name).to.beNil();
	expect(model.count).to.equal(5);
	
	NSDictionary *JSONDictionary = @{
		@"username": NSNull.null,
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};
	
	expect(adapter.JSONDictionary).to.equal(JSONDictionary);
});

it(@"should return NO and error with an invalid key path from JSON on update",^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @"bar",
		@"count": @"0"
	};
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).beFalsy();
	expect(model.name).to.equal(@"foobar");
	expect(model.count).to.equal(5);
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should return NO and error with an illegal JSON mapping on update", ^{
	NSDictionary *values = @{
		@"username": @"foo"
	};
	MTLIllegalJSONMappingModel *model = [MTLIllegalJSONMappingModel modelWithDictionary:@{
																						  } error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).beFalsy();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONMapping);
});

it(@"should support key paths across arrays on update", ^{
	NSDictionary *values = @{
	@"users": @[
			@{
				@"name": @"foo"
			},
			@{
				@"name": @"bar"
			},
			@{
				@"name": @"baz"
			}
		]
	};
	MTLArrayTestModel *model = [MTLArrayTestModel modelWithDictionary:@{
		@"names": @[
			@"foobar"
		]
	} error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(model).notTo.beNil();
	expect(error).to.beNil();
	
	expect(model.names).to.equal((@[ @"foo", @"bar", @"baz" ]));
});

it(@"should update without returning any error when using a JSON dictionary which Null.null as value",^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": NSNull.null,
		@"count": @"0"
	};
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.beNil();
});

it(@"should return NO and an error with a nil JSON dictionary on update", ^{
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:nil error:&error];
	expect(updated).beFalsy();
	expect(model.name).to.equal(@"foobar");
	expect(model.count).to.equal(5);
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should return NO and an error with a wrong data type as dictionary on update", ^{
	id wrongDictionary = @"";
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:wrongDictionary error:&error];
	expect(updated).beFalsy();
	expect(model.name).to.equal(@"foobar");
	expect(model.count).to.equal(5);
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should ignore unrecognized JSON keys on update", ^{
	NSDictionary *values = @{
							 @"foobar": @"foo",
							 @"count": @"2",
							 @"_": NSNull.null,
							 @"username": @"buzz",
							 @"nested": @{ @"name": @"bar", @"stuffToIgnore": @5, @"moreNonsense": NSNull.null },
							 };
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).notTo.beFalsy();
	expect(model.name).to.equal(@"buzz");
	expect(model.count).to.equal(2);
	expect(model.nestedName).to.equal(@"bar");
});

it(@"should fail to update if JSON dictionary validation fails", ^{
	NSDictionary *values = @{
							 @"username": @"this is too long a name",
							 };
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:values error:&error];
	expect(updated).beFalsy();
	expect(model.name).to.equal(@"foobar");
	expect(model.count).to.equal(5);
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLTestModelErrorDomain);
	expect(error.code).to.equal(MTLTestModelNameTooLong);
});

it(@"should return an error when suitable model class is found on update", ^{
	MTLSubstitutingTestModel *model = [MTLSubstitutingTestModel modelWithDictionary:@{
																					  } error:NULL];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter updateModel:model fromJSONDictionary:@{} error:&error];
	expect(updated).beFalsy();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorClassFoundOnUpdate);
});

describe(@"Deserializing multiple models", ^{
	NSDictionary *value1 = @{
							 @"username": @"foo"
							 };
	
	NSDictionary *value2 = @{
							 @"username": @"bar"
							 };
	MTLTestModel *model1 = [MTLTestModel modelWithDictionary:@{
															  @"name": @"foobar"
															  } error:NULL];
	MTLTestModel *model2 = [MTLTestModel modelWithDictionary:@{
															  @"name": @"foobar"
															  } error:NULL];
	
	NSArray *JSONModels = @[ value1, value2 ];
	NSArray *models = @[ model1, model2 ];
	
	it(@"should update models from an array of JSON dictionaries", ^{
		NSError *error = nil;
		BOOL updated = [MTLJSONAdapter upadeModels:models fromJSONArray:JSONModels error:&error];
		expect(updated).notTo.beFalsy();
		
		expect(error).to.beNil();
		expect([models[0] name]).to.equal(@"foo");
		expect([models[1] name]).to.equal(@"bar");
	});
	
	it(@"should not be affected by a NULL error parameter", ^{
		NSError *error = nil;
		NSArray *expected = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:&error];
		
		expect(models).to.equal(expected);
	});
});

it(@"should return NO and an error if it fails to update any models from an array", ^{
	NSDictionary *value1 = @{
							 @"username": @"foo",
							 @"count": @"1",
							 };
	MTLTestModel *model1 = [MTLTestModel modelWithDictionary:@{
															   @"name": @"foobar"
															   } error:NULL];
	MTLTestModel *model2 = [MTLTestModel modelWithDictionary:@{
															   @"name": @"foobar"
															   } error:NULL];
	
	NSArray *JSONModels = @[ value1 ];
	NSArray *models = @[ model1, model2 ];
	
	NSError *error = nil;
	BOOL updated = [MTLJSONAdapter upadeModels:models fromJSONArray:JSONModels error:&error];
	expect(updated).beFalsy();
	
	expect(error).toNot.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});


SpecEnd
