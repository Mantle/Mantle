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

@interface MTLURLModel : MTLModel <MTLJSONSerializing>

// Defaults to http://github.com.
@property (nonatomic, strong) NSURL *URL;

@end

// Conforms to MTLJSONSerializing but does not inherit from the MTLModel class.
@interface MTLConformingModel : NSObject <MTLJSONSerializing>

@property (nonatomic, copy) NSString *name;

@end

@interface MTLStorageBehaviorModel : MTLModel

@property (readonly, nonatomic, assign) BOOL primitive;

@property (readonly, nonatomic, assign) id assignProperty;
@property (readonly, nonatomic, weak) id weakProperty;
@property (readonly, nonatomic, strong) id strongProperty;

@end

@interface MTLBoolModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) BOOL flag;

@end

@interface MTLIDModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) id anyObject;

@end

@interface MTLNonPropertyModel : MTLModel <MTLJSONSerializing>

- (NSURL *)homepage;

@end

@interface MTLMultiKeypathModel : MTLModel <MTLJSONSerializing>

// This property is associated with the "location" and "length" keys in JSON.
@property (readonly, nonatomic, assign) NSRange range;

// This property is associated with the "nested.location" and "nested.length"
// keys in JSON.
@property (readonly, nonatomic, assign) NSRange nestedRange;

@end
