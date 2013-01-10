//
//  NSSet+MTLHigherOrderAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 15.12.11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//
//  Portions copyright (c) 2011 Bitswift. All rights reserved.
//  See the LICENSE file for more information.
//

#import "NSSet+MTLHigherOrderAdditions.h"
#import "EXTScope.h"
#import <libkern/OSAtomic.h>

@implementation NSSet (MTLHigherOrderAdditions)

- (id)mtl_filterUsingBlock:(BOOL (^)(id obj))block; {
    return [self mtl_filterWithOptions:0 usingBlock:block];
}

- (id)mtl_filterWithOptions:(NSEnumerationOptions)opts usingBlock:(BOOL (^)(id obj))block; {
    return [self objectsWithOptions:opts passingTest:^(id obj, BOOL *stop){
        return block(obj);
    }];
}

- (id)mtl_filterWithFailedObjects:(NSSet **)failedObjects usingBlock:(BOOL(^)(id obj))block; {
    return [self mtl_filterWithOptions:0 failedObjects:failedObjects usingBlock:block];
}

- (id)mtl_filterWithOptions:(NSEnumerationOptions)opts failedObjects:(NSSet **)failedObjects usingBlock:(BOOL(^)(id obj))block; {
    NSUInteger originalCount = [self count];
    BOOL concurrent = (opts & NSEnumerationConcurrent);

    // this will be used to store both the successful objects (starting from the
    // beginning) and the failed objects (starting from the end)
    //
    // note that we don't need to retain the objects, since the set is already
    // doing so
    __unsafe_unretained volatile id *objects = (__unsafe_unretained id *)calloc(originalCount, sizeof(*objects));
    if (objects == NULL) {
        return nil;
    }

    @onExit {
        free((void *)objects);
    };

    volatile int64_t nextSuccessIndex = 0;
    volatile int64_t *nextSuccessIndexPtr = &nextSuccessIndex;

    volatile int64_t nextFailureIndex = originalCount - 1;
    volatile int64_t *nextFailureIndexPtr = &nextFailureIndex;

    [self enumerateObjectsWithOptions:opts usingBlock:^(id obj, BOOL *stop){
        BOOL result = block(obj);

        int64_t index;
        
        // find the index to store into the array
        if (result) {
            int64_t indexPlusOne = OSAtomicIncrement64Barrier(nextSuccessIndexPtr);
            index = indexPlusOne - 1;
        } else {
            int64_t indexMinusOne = OSAtomicDecrement64Barrier(nextFailureIndexPtr);
            index = indexMinusOne + 1;
        }

        objects[index] = obj;
    }];

    if (concurrent) {
        // finish all assignments into the 'objects' array
        OSMemoryBarrier();
    }

    NSUInteger successCount = (NSUInteger)nextSuccessIndex;
    NSUInteger failureCount = originalCount - 1 - (NSUInteger)nextFailureIndex;

    if (failedObjects != NULL) {
        *failedObjects = [NSSet setWithObjects:(__unsafe_unretained id *)(objects + nextFailureIndex + 1) count:failureCount];
    }

    return [NSSet setWithObjects:(id *)objects count:successCount];
}

- (id)mtl_foldWithValue:(id)startingValue usingBlock:(id (^)(id left, id right))block; {
    __block id value = startingValue;

    [self enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
        value = block(value, obj);
    }];

    return value;
}

- (id)mtl_mapUsingBlock:(id (^)(id obj))block; {
    return [self mtl_mapWithOptions:0 usingBlock:block];
}

- (id)mtl_mapWithOptions:(NSEnumerationOptions)opts usingBlock:(id (^)(id obj))block; {
    NSUInteger originalCount = [self count];
    BOOL concurrent = (opts & NSEnumerationConcurrent);

    __strong volatile id *objects = (__strong id *)calloc(originalCount, sizeof(*objects));
    if (objects == NULL) {
        return nil;
    }

    // declare these variables way up here so that it can be used in the @onExit
    // block below (avoiding unnecessary iteration)
    volatile int64_t nextIndex = 0;
    volatile int64_t *nextIndexPtr = &nextIndex;

    @onExit {
        // nil out everything in the array to make sure ARC releases
        // everything appropriately
        NSUInteger actualCount = (NSUInteger)*nextIndexPtr;
        for (NSUInteger i = 0;i < actualCount;++i) {
            objects[i] = nil;
        }

        free((void *)objects);
    };

    [self enumerateObjectsWithOptions:opts usingBlock:^(id obj, BOOL *stop){
        id result = block(obj);
        
        if (result == nil) {
            // don't increment the index, go on to the next object
            return;
        }

        // find the index to store into the array -- 'nextIndex' is updated to
        // reflect the total number of elements
        int64_t indexPlusOne = OSAtomicIncrement64Barrier(nextIndexPtr);
        objects[indexPlusOne - 1] = result;
    }];

    if (concurrent) {
        // finish all assignments into the 'objects' array
        OSMemoryBarrier();
    }

    return [NSSet setWithObjects:(id *)objects count:(NSUInteger)nextIndex];
}

- (id)mtl_objectPassingTest:(BOOL (^)(id obj, BOOL *stop))predicate; {
    return [self mtl_objectWithOptions:0 passingTest:predicate];
}

- (id)mtl_objectWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, BOOL *stop))predicate; {
    BOOL concurrent = (opts & NSEnumerationConcurrent);

    void * volatile match = NULL;
    void * volatile * matchPtr = &match;

    [self enumerateObjectsWithOptions:opts usingBlock:^(id obj, BOOL *stop){
        BOOL passed = predicate(obj, stop);
        if (!passed) return;

        if (concurrent) {
            // we don't use a barrier because it doesn't really matter if we
            // overwrite a previous value, since we can match any object from
            // the set
            OSAtomicCompareAndSwapPtr(*matchPtr, (__bridge void *)obj, matchPtr);
        } else {
            *matchPtr = (__bridge void *)obj;
        }
    }];

    if (concurrent) {
        // make sure that any compare-and-swaps complete
        OSMemoryBarrier();
    }

    // call through -self to remove a bogus analyzer warning about returning
    // a stack-local object (we're not)
    return [(__bridge id)match self];
}

- (BOOL)mtl_anyObjectPassingTest:(BOOL (^)(id obj))predicate {
	NSParameterAssert(predicate != NULL);

	return [self mtl_objectPassingTest:^(id obj, BOOL *stop) {
		BOOL passes = predicate(obj);
		if (passes) *stop = YES;
		return passes;
	}] != nil;
}

@end
