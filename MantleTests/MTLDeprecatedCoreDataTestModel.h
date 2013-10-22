//
//  MTLDeprecatedCoreDataTestModel.h
//  Mantle
//
//  Created by Robert Böhnke on 10/21/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>

// Corresponds to the `Parent` entity.
@interface MTLDeprecatedParentTestModel : MTLModel <MTLManagedObjectSerializing>

// Associated with the `number` attribute.
@property (nonatomic, copy) NSString *numberString;

@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSString *requiredString;

@property (nonatomic, copy) NSURL *URL;

@property (nonatomic, copy) NSArray *orderedChildren;
@property (nonatomic, copy) NSSet *unorderedChildren;

@end