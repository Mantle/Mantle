//
//  MTLTestModel.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

extern NSString * const MTLTestModelErrorDomain;
extern const NSInteger MTLTestModelNameTooLong;
extern const NSInteger MTLTestModelNameMissing;

@interface MTLEmptyTestModel : MTLModel
@end

@interface MTLTestModel : MTLModel <MTLJSONSerializing>

// Defaults to 1. This changes the behavior of some of the receiver's methods to
// emulate a migration.
+ (void)setModelVersion:(NSUInteger)version;

// Must be less than 10 characters.
//
// This property is associated with a "username" key in JSON.
@property (nonatomic, copy) NSString *name;

// Defaults to 1. When two models are merged, their counts are added together.
//
// This property is a string in JSON.
@property (nonatomic, assign) NSUInteger count;

// This property is associated with a "nested.name" key path in JSON. This
// property should not be encoded into new archives.
@property (nonatomic, copy) NSString *nestedName;

// Should not be stored in the dictionary value or JSON.
@property (nonatomic, copy, readonly) NSString *dynamicName;

// Should not be stored in JSON, has MTLPropertyStorageTransitory.
@property (nonatomic, weak) MTLEmptyTestModel *weakModel;

@end

// Parses MTLTestModel objects from JSON instead.
@interface MTLSubstitutingTestModel : MTLModel <MTLJSONSerializing>
@end

@interface MTLValidationModel : MTLModel

// Defaults to nil, which is not considered valid.
@property (nonatomic, copy) NSString *name;

@end

// Returns a default name of 'foobar' when validateName:error: is invoked
@interface MTLSelfValidatingModel : MTLValidationModel
@end

@interface MTLURLModel : MTLModel <MTLJSONSerializing>

// Defaults to http://github.com.
//
// Uses the MTLURLValueTransformerName transformer to serialize to an NSString.
@property (nonatomic, strong) NSURL *URL;

@end

@interface MTLStorageBehaviorModel : MTLModel

@property (readonly, nonatomic, assign) BOOL primitive;

@property (readonly, nonatomic, assign) id assignProperty;
@property (readonly, nonatomic, weak) id weakProperty;
@property (readonly, nonatomic, strong) id strongProperty;

@property (readonly, nonatomic, strong) id notIvarBacked;

@end
