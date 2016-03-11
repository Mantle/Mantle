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

// Should not be stored in JSON, has MTLPropertyStorageTransitory.
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

@interface MTLValidationModel : MTLModel <MTLJSONSerializing>

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

@interface MTLURLSubclassModel : MTLURLModel

// Defaults to http://github.com/Mantle/Mantle.
@property (nonatomic, strong) NSURL *otherURL;

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

@property (readonly, nonatomic, strong) id shadowedInSubclass;
@property (readonly, nonatomic, strong) id declaredInProtocol;

@end

@protocol MTLDateProtocol <NSObject>

@property (readonly, nonatomic, strong) id declaredInProtocol;

@end

@interface MTLStorageBehaviorModelSubclass : MTLStorageBehaviorModel <MTLDateProtocol>

@property (readonly, nonatomic, strong) id shadowedInSubclass;

@end

@interface MTLBoolModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) BOOL flag;

@end

@interface MTLStringModel : MTLModel <MTLJSONSerializing>

@property (readwrite, nonatomic, copy) NSString *string;

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

@interface MTLClassClusterModel : MTLModel <MTLJSONSerializing>

@property (readonly, nonatomic, copy) NSString *flavor;

@end

@interface MTLChocolateClassClusterModel : MTLClassClusterModel

// Associated with the "chocolate_bitterness" JSON key and transformed to a
// string.
@property (readwrite, nonatomic, assign) NSUInteger bitterness;

@end

@interface MTLStrawberryClassClusterModel : MTLClassClusterModel

// Associated with the "strawberry_freshness" JSON key.
@property (readwrite, nonatomic, assign) NSUInteger freshness;

@end


@protocol MTLOptionalPropertyProtocol

@optional
@property (readwrite, nonatomic, strong) id optionalUnimplementedProperty;
@property (readwrite, nonatomic, strong) id optionalImplementedProperty;

@end

@interface MTLOptionalPropertyModel : MTLModel <MTLOptionalPropertyProtocol>

@property (readwrite, nonatomic, strong) id optionalImplementedProperty;

@end


@interface MTLRecursiveUserModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSArray *groups;

@end

@interface MTLRecursiveGroupModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, readonly) MTLRecursiveUserModel *owner;
@property (nonatomic, readonly) NSArray *users;
@end

@interface MTLPropertyDefaultAdapterModel : MTLModel<MTLJSONSerializing>

@property (readwrite, nonatomic, strong) MTLEmptyTestModel *nonConformingMTLJSONSerializingProperty;
@property (readwrite, nonatomic, strong) MTLTestModel *conformingMTLJSONSerializingProperty;
@property (readwrite, nonatomic, strong) NSString *property;

@end
