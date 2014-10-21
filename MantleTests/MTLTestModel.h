//
//  MTLTestModel.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>

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

// Should not be stored in JSON.
@property (nonatomic, weak) MTLEmptyTestModel *weakModel;

@end

@interface MTLSubclassTestModel : MTLTestModel

// Properties to test merging between subclass and superclass
@property (nonatomic, copy) NSString *role;
@property (nonatomic, copy) NSNumber *generation;

@end

@interface MTLArrayTestModel : MTLModel <MTLJSONSerializing>

// This property is associated with a "users.username" key in JSON.
@property (nonatomic, copy) NSString *names;

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

// Maps a non-existant property "name" to the "username" key in JSON.
@interface MTLIllegalJSONMappingModel : MTLModel <MTLJSONSerializing>
@end
