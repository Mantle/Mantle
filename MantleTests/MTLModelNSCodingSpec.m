//
//  MTLModelNSCodingSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-02-13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <Nimble/Nimble.h>
#import <Quick/Quick.h>

#import "MTLTestModel.h"

QuickSpecBegin(MTLModelNSCoding)

it(@"should have default encoding behaviors", ^{
	NSDictionary *behaviors = MTLTestModel.encodingBehaviorsByPropertyKey;
	expect(behaviors).notTo(beNil());

	expect(behaviors[@"name"]).to(equal(@(MTLModelEncodingBehaviorUnconditional)));
	expect(behaviors[@"count"]).to(equal(@(MTLModelEncodingBehaviorUnconditional)));
	expect(behaviors[@"weakModel"]).to(equal(@(MTLModelEncodingBehaviorConditional)));
	expect(behaviors[@"dynamicName"]).to(beNil());
});

it(@"should have default allowed classes", ^{
	NSDictionary *allowedClasses = MTLTestModel.allowedSecureCodingClassesByPropertyKey;
	expect(allowedClasses).notTo(beNil());

	expect(allowedClasses[@"name"]).to(equal(@[ NSString.class ]));
	expect(allowedClasses[@"count"]).to(equal(@[ NSValue.class ]));
	expect(allowedClasses[@"weakModel"]).to(equal(@[ MTLEmptyTestModel.class ]));

	// Not encoded into archives.
	expect(allowedClasses[@"nestedName"]).to(beNil());
	expect(allowedClasses[@"dynamicName"]).to(beNil());
});

it(@"should default to version 0", ^{
	expect(@(MTLEmptyTestModel.modelVersion)).to(equal(@0));
});

describe(@"archiving", ^{
	__block MTLEmptyTestModel *emptyModel;
	__block MTLTestModel *model;
	__block NSDictionary *values;

	__block MTLTestModel * (^archiveAndUnarchiveModel)(void);

	beforeEach(^{
		emptyModel = [[MTLEmptyTestModel alloc] init];
		expect(emptyModel).notTo(beNil());

		values = @{
			@"name": @"foobar",
			@"count": @5,
		};

		NSError *error = nil;
		model = [[MTLTestModel alloc] initWithDictionary:values error:&error];
		expect(model).notTo(beNil());
		expect(error).to(beNil());

		archiveAndUnarchiveModel = [^{
			NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
			expect(data).notTo(beNil());

			MTLTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			expect(unarchivedModel).notTo(beNil());

			return unarchivedModel;
		} copy];
	});

	it(@"should archive unconditional properties", ^{
		expect(archiveAndUnarchiveModel()).to(equal(model));
	});

	it(@"should not archive excluded properties", ^{
		model.nestedName = @"foobar";

		MTLTestModel *unarchivedModel = archiveAndUnarchiveModel();
		expect(unarchivedModel.nestedName).to(beNil());
		expect(unarchivedModel).notTo(equal(model));

		model.nestedName = nil;
		expect(unarchivedModel).to(equal(model));
	});

	it(@"should not archive conditional properties if not encoded elsewhere", ^{
		model.weakModel = emptyModel;

		MTLTestModel *unarchivedModel = archiveAndUnarchiveModel();
		expect(unarchivedModel.weakModel).to(beNil());
	});

	it(@"should archive conditional properties if encoded elsewhere", ^{
		model.weakModel = emptyModel;

		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@[ model, emptyModel ]];
		expect(data).notTo(beNil());

		NSArray *objects = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		expect(@(objects.count)).to(equal(@2));
		expect(objects[1]).to(equal(emptyModel));

		MTLTestModel *unarchivedModel = objects[0];
		expect(unarchivedModel).to(equal(model));
		expect(unarchivedModel.weakModel).to(equal(emptyModel));
	});

	it(@"should invoke custom decoding logic", ^{
		MTLTestModel.modelVersion = 0;

		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
		expect(data).notTo(beNil());

		MTLTestModel.modelVersion = 1;

		MTLTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		expect(unarchivedModel).notTo(beNil());
		expect(unarchivedModel.name).to(equal(@"M: foobar"));
		expect(@(unarchivedModel.count)).to(equal(@5));
	});

	it(@"should unarchive an external representation from the old model format", ^{
		NSURL *archiveURL = [[NSBundle bundleForClass:self.class] URLForResource:@"MTLTestModel-OldArchive" withExtension:@"plist"];
		expect(archiveURL).notTo(beNil());

		MTLTestModel *unarchivedModel = [NSKeyedUnarchiver unarchiveObjectWithFile:archiveURL.path];
		expect(unarchivedModel).notTo(beNil());

		NSDictionary *expectedValues = @{
			@"name": @"foobar",
			@"count": @5,
			@"nestedName": @"fuzzbuzz",
			@"weakModel": NSNull.null,
		};

		expect(unarchivedModel.dictionaryValue).to(equal(expectedValues));
	});
});

QuickSpecEnd
