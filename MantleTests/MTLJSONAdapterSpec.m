//
//  MTLJSONAdapterSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLTestModel.h"

SpecBegin(MTLJSONAdapter)

it(@"should initialize from JSON", ^{
	NSDictionary *values = @{
		@"username": NSNull.null,
		@"count": @"5",
	};

	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:values modelClass:MTLTestModel.class error:&error];
	expect(adapter).notTo.beNil();
	expect(error).to.beNil();

	MTLTestModel *model = (id)adapter.model;
	expect(model).notTo.beNil();
	expect(model.name).to.beNil();
	expect(model.count).to.equal(5);
	
	NSDictionary *JSONDictionary = @{
		@"username": NSNull.null,
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};

	expect(adapter.JSONDictionary).to.equal(JSONDictionary);
});

it(@"should initialize from a model", ^{
	MTLTestModel *model = [MTLTestModel modelWithDictionary:@{
		@"name": @"foobar",
		@"count": @5,
	} error:NULL];

	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithModel:model];
	expect(adapter).notTo.beNil();
	expect(adapter.model).to.beIdenticalTo(model);

	NSDictionary *JSONDictionary = @{
		@"username": @"foobar",
		@"count": @"5",
		@"nested": @{ @"name": NSNull.null },
	};

	expect(adapter.JSONDictionary).to.equal(JSONDictionary);
});

it(@"should initialize nested key paths from JSON", ^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @{ @"name": @"bar" },
		@"count": @"0"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.equal(@"bar");

	expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(values);
});

it(@"should return nil and error with an invalid key path from JSON",^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @"bar",
		@"count": @"0"
	};
	
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should return nil and error with an illegal JSON mapping", ^{
	NSDictionary *values = @{
		@"username": @"foo"
	};

	NSError *error = nil;
	MTLIllegalJSONMappingModel *model = [MTLJSONAdapter modelOfClass:MTLIllegalJSONMappingModel.class fromJSONDictionary:values error:&error];
	expect(model).beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONMapping);
});

it(@"should support key paths across arrays", ^{
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

	NSError *error = nil;
	MTLArrayTestModel *model = [MTLJSONAdapter modelOfClass:MTLArrayTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	expect(model.names).to.equal((@[ @"foo", @"bar", @"baz" ]));
});

it(@"should initialize without returning any error when using a JSON dictionary which Null.null as value",^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": NSNull.null,
		@"count": @"0"
	};
	
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();
	
	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.beNil();
});

it(@"should return nil and an error with a nil JSON dictionary", ^{
	NSError *error = nil;
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:nil modelClass:MTLTestModel.class error:&error];
	expect(adapter).to.beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should return nil and an error with a wrong data type as dictionary", ^{
	NSError *error = nil;
	id wrongDictionary = @"";
	MTLJSONAdapter *adapter = [[MTLJSONAdapter alloc] initWithJSONDictionary:wrongDictionary modelClass:MTLTestModel.class error:&error];
	expect(adapter).to.beNil();
	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorInvalidJSONDictionary);
});

it(@"should ignore unrecognized JSON keys", ^{
	NSDictionary *values = @{
		@"foobar": @"foo",
		@"count": @"2",
		@"_": NSNull.null,
		@"username": @"buzz",
		@"nested": @{ @"name": @"bar", @"stuffToIgnore": @5, @"moreNonsense": NSNull.null },
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).notTo.beNil();
	expect(error).to.beNil();

	expect(model.name).to.equal(@"buzz");
	expect(model.count).to.equal(2);
	expect(model.nestedName).to.equal(@"bar");
});

it(@"should fail to initialize if JSON dictionary validation fails", ^{
	NSDictionary *values = @{
		@"username": @"this is too long a name",
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLTestModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beNil();
	expect(error.domain).to.equal(MTLTestModelErrorDomain);
	expect(error.code).to.equal(MTLTestModelNameTooLong);
});

it(@"should parse a different model class", ^{
	NSDictionary *values = @{
		@"username": @"foo",
		@"nested": @{ @"name": @"bar" },
		@"count": @"0"
	};

	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLSubstitutingTestModel.class fromJSONDictionary:values error:&error];
	expect(model).to.beKindOf(MTLTestModel.class);
	expect(error).to.beNil();

	expect(model.name).to.equal(@"foo");
	expect(model.count).to.equal(0);
	expect(model.nestedName).to.equal(@"bar");

	expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(values);
});

it(@"should return an error when no suitable model class is found", ^{
	NSError *error = nil;
	MTLTestModel *model = [MTLJSONAdapter modelOfClass:MTLSubstitutingTestModel.class fromJSONDictionary:@{} error:&error];
	expect(model).to.beNil();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorNoClassFound);
});

describe(@"Deserializing multiple models", ^{
	NSDictionary *value1 = @{
		@"username": @"foo"
	};

	NSDictionary *value2 = @{
		@"username": @"bar"
	};

	NSArray *JSONModels = @[ value1, value2 ];

	it(@"should initialize models from an array of JSON dictionaries", ^{
		NSError *error = nil;
		NSArray *mantleModels = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:&error];

		expect(error).to.beNil();
		expect(mantleModels).toNot.beNil();
		expect(mantleModels).haveCountOf(2);
		expect([mantleModels[0] name]).to.equal(@"foo");
		expect([mantleModels[1] name]).to.equal(@"bar");
	});

	it(@"should not be affected by a NULL error parameter", ^{
		NSError *error = nil;
		NSArray *expected = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:&error];
		NSArray *models = [MTLJSONAdapter modelsOfClass:MTLTestModel.class fromJSONArray:JSONModels error:NULL];

		expect(models).to.equal(expected);
	});
});

it(@"should return nil and an error if it fails to initialize any model from an array", ^{
	NSDictionary *value1 = @{
		@"username": @"foo",
		@"count": @"1",
	};

	NSDictionary *value2 = @{
		@"count": @[ @"This won't parse" ],
	};

	NSArray *JSONModels = @[ value1, value2 ];

	NSError *error = nil;
	NSArray *mantleModels = [MTLJSONAdapter modelsOfClass:MTLSubstitutingTestModel.class fromJSONArray:JSONModels error:&error];

	expect(error).toNot.beNil();
	expect(error.domain).to.equal(MTLJSONAdapterErrorDomain);
	expect(error.code).to.equal(MTLJSONAdapterErrorNoClassFound);
	expect(mantleModels).to.beNil();
});

it(@"should return an array of dictionaries from models", ^{
	MTLTestModel *model1 = [[MTLTestModel alloc] init];
	model1.name = @"foo";

	MTLTestModel *model2 = [[MTLTestModel alloc] init];
	model2.name = @"bar";

	NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:@[ model1, model2 ]];

	expect(JSONArray).toNot.beNil();
	expect(JSONArray).haveCountOf(2);
	expect(JSONArray[0][@"username"]).to.equal(@"foo");
	expect(JSONArray[1][@"username"]).to.equal(@"bar");
});

// Update

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
