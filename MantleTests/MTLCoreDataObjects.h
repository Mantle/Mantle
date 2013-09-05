//
//  MTLCoreDataObjects.h
//  Mantle
//
//  Created by Robert Böhnke on 9/4/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MTLParent;

@interface MTLChild : NSManagedObject

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext*)moc;

@property (readwrite, nonatomic, strong) NSNumber *childID;

@property (readwrite, nonatomic, strong) MTLParent *parent1;
@property (readwrite, nonatomic, strong) MTLParent *parent2;

@end

@interface MTLParent : NSManagedObject

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext*)moc;

@property (readwrite, nonatomic, strong) NSDate *date;
@property (readwrite, nonatomic, strong) NSNumber* number;
@property (readwrite, nonatomic, copy) NSString *string;

@property (readwrite, nonatomic, copy) NSOrderedSet *orderedChildren;
@property (readwrite, nonatomic, copy) NSSet *unorderedChildren;

@end


@interface MTLParent (CoreDataGeneratedAccesssors)

- (void)addOrderedChildren:(NSOrderedSet*)orderedChildren;
- (void)removeOrderedChildren:(NSOrderedSet*)orderedChildren;

- (void)addOrderedChildrenObject:(MTLChild*)child;
- (void)removeOrderedChildrenObject:(MTLChild*)child;

- (void)addUnorderedChildren:(NSSet*)unorderedChildren;
- (void)removeUnorderedChildren:(NSSet*)unorderedChildren;

- (void)addUnorderedChildrenObject:(MTLChild*)child;
- (void)removeUnorderedChildrenObject:(MTLChild*)child;

@end
