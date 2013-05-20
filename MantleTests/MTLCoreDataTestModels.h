//
//  MTLCoreDataTestModels.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-04-05.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Mantle/Mantle.h>
#import <CoreData/CoreData.h>

// Corresponds to the `Parent` entity.
@interface MTLParentTestModel : MTLModel <MTLManagedObjectSerializing>

// Associated with the `number` attribute.
@property (nonatomic, copy) NSString *numberString;

@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSString *requiredString;

@property (nonatomic, copy) NSArray *orderedChildren;
@property (nonatomic, copy) NSSet *unorderedChildren;

@end

// Corresponds to the `Child` entity.
@interface MTLChildTestModel : MTLModel <MTLManagedObjectSerializing>

// Associated with the `id` attribute.
@property (nonatomic, assign) NSUInteger childID;

@property (nonatomic, weak) MTLParentTestModel *parent1;
@property (nonatomic, weak) MTLParentTestModel *parent2;

@end
