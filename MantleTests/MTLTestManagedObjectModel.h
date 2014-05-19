//
//  MTLTestManagedObjectModel.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

extern NSString * const MTLTestManagedObjectModelErrorDomain;
extern const NSInteger MTLTestManagedObjectModelNameTooLong;
extern const NSInteger MTLTestManagedObjectModelNameMissing;

@interface MTLEmptyTestManagedObjectModel : MTLManagedObjectModel

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc;

@end

@interface MTLTestManagedObjectModel : MTLManagedObjectModel <MTLJSONSerializing>

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc;

// Must be less than 10 characters.
//
// This property is associated with a "username" key in JSON.
@property (nonatomic, retain) NSString *name;

// Defaults to 1. When two models are merged, their counts are added together.
//
// This property is a string in JSON.
@property (nonatomic, assign) NSUInteger count;

// This property is associated with a "nested.name" key path in JSON. This
// property should not be encoded into new archives.
@property (nonatomic, retain) NSString *nestedName;

// Should not be stored in the dictionary value or JSON.
@property (nonatomic, copy, readonly) NSString *dynamicName;

// Should not be stored in JSON.
@property (nonatomic, retain) MTLEmptyTestManagedObjectModel *weakModel;

@end

@interface MTLSubclassTestManagedObjectModel : MTLTestManagedObjectModel

// Properties to test merging between subclass and superclass
@property (nonatomic, retain) NSString *role;
@property (nonatomic, retain) NSNumber *generation;

@end

//@interface MTLArrayTestManagedObjectModel : MTLManagedObjectModel <MTLJSONSerializing>
//
//// This property is associated with a "users.username" key in JSON.
//@property (nonatomic, copy) NSArray *names;
//
//@end
//
//// Parses MTLTestManagedObjectModel objects from JSON instead.
//@interface MTLSubstitutingTestManagedObjectModel : MTLManagedObjectModel <MTLJSONSerializing>
//@end
//
//@interface MTLValidationManagedObjectModel : MTLManagedObjectModel
//
//// Defaults to nil, which is not considered valid.
//@property (nonatomic, copy) NSString *name;
//
//@end
//
//// Returns a default name of 'foobar' when validateName:error: is invoked
//@interface MTLSelfValidatingManagedObjectModel : MTLValidationManagedObjectModel
//@end
//
//// Maps a non-existant property "name" to the "username" key in JSON.
//@interface MTLIllegalJSONMappingManagedObjectModel : MTLManagedObjectModel <MTLJSONSerializing>
//@end
