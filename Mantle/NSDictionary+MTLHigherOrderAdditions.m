//
//  NSDictionary+MTLHigherOrderAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 15.12.11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//
//  Portions copyright (c) 2011 Bitswift. All rights reserved.
//  See the LICENSE file for more information.
//

#import "NSDictionary+MTLHigherOrderAdditions.h"
#import "EXTScope.h"
#import <libkern/OSAtomic.h>

@implementation NSDictionary (MTLHigherOrderAdditions)

- (NSDictionary *)mtl_filterEntriesUsingBlock:(BOOL (^)(id key, id value))block; {
    return [self mtl_filterEntriesWithOptions:0 usingBlock:block];
}

- (NSDictionary *)mtl_filterEntriesWithOptions:(NSEnumerationOptions)opts usingBlock:(BOOL (^)(id key, id value))block; {
    NSSet *matchingKeys = [self keysOfEntriesWithOptions:opts passingTest:^(id key, id value, BOOL *stop){
        return block(key, value);
    }];

    NSArray *keys = [matchingKeys allObjects];
    NSArray *values = [self objectsForKeys:keys notFoundMarker:[NSNull null]];

    return [NSDictionary dictionaryWithObjects:values forKeys:keys];
}

- (NSDictionary *)mtl_filterEntriesWithFailedEntries:(NSDictionary **)failedEntries usingBlock:(BOOL(^)(id key, id value))block; {
    return [self mtl_filterEntriesWithOptions:0 failedEntries:failedEntries usingBlock:block];
}

- (NSDictionary *)mtl_filterEntriesWithOptions:(NSEnumerationOptions)opts failedEntries:(NSDictionary **)failedEntries usingBlock:(BOOL(^)(id key, id value))block; {
    NSUInteger originalCount = [self count];
    BOOL concurrent = (opts & NSEnumerationConcurrent);

    // this will be used to store both the successful keys (starting from the
    // beginning) and the failed keys (starting from the end)
    // 
    // note that we don't need to retain the objects, since the dictionary is already
    // doing so
    __unsafe_unretained volatile id *keys = (__unsafe_unretained id *)calloc(originalCount, sizeof(*keys));
    if (keys == NULL) {
        return nil;
    }

    @onExit {
        free((void *)keys);
    };

    // this will be used to store both the successful values (starting from the
    // beginning) and the failed values (starting from the end)
    // 
    // note that we don't need to retain the objects, since the dictionary is already
    // doing so
    __unsafe_unretained volatile id *values = (__unsafe_unretained id *)calloc(originalCount, sizeof(*values));
    if (values == NULL) {
        return nil;
    }

    @onExit {
        free((void *)values);
    };

    volatile int64_t nextSuccessIndex = 0;
    volatile int64_t *nextSuccessIndexPtr = &nextSuccessIndex;

    volatile int64_t nextFailureIndex = originalCount - 1;
    volatile int64_t *nextFailureIndexPtr = &nextFailureIndex;

    [self enumerateKeysAndObjectsWithOptions:opts usingBlock:^(id key, id value, BOOL *stop){
        BOOL result = block(key, value);

        int64_t index;

        // find the index to store into the arrays
        if (result) {
            int64_t indexPlusOne = OSAtomicIncrement64Barrier(nextSuccessIndexPtr);
            index = indexPlusOne - 1;
        } else {
            int64_t indexMinusOne = OSAtomicDecrement64Barrier(nextFailureIndexPtr);
            index = indexMinusOne + 1;
        }
        
        keys[index] = key;
        values[index] = value;
    }];

    if (concurrent) {
        // finish all assignments into the 'keys' and 'values' arrays
        OSMemoryBarrier();
    }

    NSUInteger successCount = (NSUInteger)nextSuccessIndex;
    NSUInteger failureCount = originalCount - 1 - (NSUInteger)nextFailureIndex;

    if (failedEntries) {
        size_t objectsOffset = (size_t)(nextFailureIndex + 1);

        *failedEntries = [NSDictionary dictionaryWithObjects:(__unsafe_unretained id *)(values + objectsOffset) forKeys:(__unsafe_unretained id *)(keys + objectsOffset) count:failureCount];
    }

    return [NSDictionary dictionaryWithObjects:(id *)values forKeys:(id *)keys count:successCount];
}

- (id)mtl_foldEntriesWithValue:(id)startingValue usingBlock:(id (^)(id left, id rightKey, id rightValue))block; {
    __block id value = startingValue;
    
    [self enumerateKeysAndObjectsUsingBlock:^(id dictionaryKey, id dictionaryValue, BOOL *stop){
        value = block(value, dictionaryKey, dictionaryValue);
    }];

    return value;
}

- (NSDictionary *)mtl_mapValuesUsingBlock:(id (^)(id key, id value))block; {
    return [self mtl_mapValuesWithOptions:0 usingBlock:block];
}

- (NSDictionary *)mtl_mapValuesWithOptions:(NSEnumerationOptions)opts usingBlock:(id (^)(id key, id value))block; {
    NSUInteger originalCount = [self count];
    BOOL concurrent = (opts & NSEnumerationConcurrent);

    // we don't need to retain the individual keys, since the original
    // dictionary is already doing so, and the keys themselves won't change
    __unsafe_unretained volatile id *keys = (__unsafe_unretained id *)calloc(originalCount, sizeof(*keys));
    if (keys == NULL) {
        return nil;
    }

    @onExit {
        free((void *)keys);
    };

    __strong volatile id *values = (__strong id *)calloc(originalCount, sizeof(*values));
    if (values == NULL) {
        return nil;
    }

    // declare these variables way up here so that they can be used in the
    // @onExit block below (avoiding unnecessary iteration)
    volatile int64_t nextIndex = 0;
    volatile int64_t *nextIndexPtr = &nextIndex;

    @onExit {
        // nil out everything in the 'values' array to make sure ARC releases
        // everything appropriately
        NSUInteger actualCount = (NSUInteger)*nextIndexPtr;
        for (NSUInteger i = 0;i < actualCount;++i) {
            values[i] = nil;
        }

        free((void *)values);
    };

    [self enumerateKeysAndObjectsWithOptions:opts usingBlock:^(id key, id value, BOOL *stop){
        id newValue = block(key, value);
        
        if (newValue == nil) {
            // don't increment the index, go on to the next object
            return;
        }

        // find the index to store into the array -- 'nextIndex' is updated to
        // reflect the total number of elements
        int64_t indexPlusOne = OSAtomicIncrement64Barrier(nextIndexPtr);

        keys[indexPlusOne - 1] = key;
        values[indexPlusOne - 1] = newValue;
    }];

    if (concurrent) {
        // finish all assignments into the 'keys' and 'values' arrays
        OSMemoryBarrier();
    }

    return [NSDictionary dictionaryWithObjects:(id *)values forKeys:(id *)keys count:(NSUInteger)nextIndex];
}

- (id)mtl_keyOfEntryPassingTest:(BOOL (^)(id key, id obj, BOOL *stop))predicate; {
    return [self mtl_keyOfEntryWithOptions:0 passingTest:predicate];
}

- (id)mtl_keyOfEntryWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id key, id obj, BOOL *stop))predicate; {
    BOOL concurrent = (opts & NSEnumerationConcurrent);

    void * volatile match = NULL;
    void * volatile * matchPtr = &match;

    [self enumerateKeysAndObjectsWithOptions:opts usingBlock:^(id key, id obj, BOOL *stop){
        BOOL passed = predicate(key, obj, stop);
        if (!passed) return;

        if (concurrent) {
            // we don't use a barrier because it doesn't really matter if we
            // overwrite a previous value, since we can match any object from
            // the set
            OSAtomicCompareAndSwapPtr(*matchPtr, (__bridge void *)key, matchPtr);
        } else {
            *matchPtr = (__bridge void *)key;
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

@end
