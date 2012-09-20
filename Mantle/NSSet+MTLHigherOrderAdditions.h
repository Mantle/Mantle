//
//  NSSet+MTLHigherOrderAdditions.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 15.12.11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//
//  Portions copyright (c) 2011 Bitswift. All rights reserved.
//  See the LICENSE file for more information.
//

#import <Foundation/Foundation.h>

/**
 * Higher-order functions for `NSSet`.
 */
@interface NSSet (MTLHigherOrderAdditions)

/**
 * Filters the objects of the receiver with the given predicate, returning a new
 * set built from those objects.
 *
 * @param block A predicate block that determines whether to include or exclude
 * a given object.
 */
- (id)mtl_filterUsingBlock:(BOOL (^)(id obj))block;

/**
 * Filters the objects of the receiver with the given predicate, according to
 * the semantics of `opts`, returning a new set built from those objects.
 *
 * @param opts A mask of `NSEnumerationOptions` to apply when filtering.
 * @param block A predicate block that determines whether to include or exclude
 * a given object.
 */
- (id)mtl_filterWithOptions:(NSEnumerationOptions)opts usingBlock:(BOOL (^)(id obj))block;

/**
 * Returns an set of filtered objects for which `block` returns `YES`, and
 * sets `failedObjects` to an set of the objects for which `block` returned
 * `NO`.
 *
 * @param failedObjects If not `NULL`, this will be a collection of all the
 * objects for which `block` returned `NO`. If no objects failed, this will be
 * an empty set.
 * @param block A predicate with which to filter objects in the receiver. If
 * this block returns `YES`, the object will be added to the returned
 * collection. If this block returns `NO`, the object will be added to
 * `failedObjects`.
 */
- (id)mtl_filterWithFailedObjects:(NSSet **)failedObjects usingBlock:(BOOL(^)(id obj))block;

/**
 * Returns an set of filtered objects for which `block` returns `YES`, and
 * sets `failedObjects` to an set of the objects for which `block` returned
 * `NO`, applying `opts` while filtering.
 *
 * @param opts A mask of `NSEnumerationOptions` to apply when filtering.
 * @param failedObjects If not `NULL`, this will be a collection of all the
 * objects for which `block` returned `NO`. If no objects failed, this will be
 * an empty set.
 * @param block A predicate with which to filter objects in the receiver. If
 * this block returns `YES`, the object will be added to the returned
 * collection. If this block returns `NO`, the object will be added to
 * `failedObjects`.
 */
- (id)mtl_filterWithOptions:(NSEnumerationOptions)opts failedObjects:(NSSet **)failedObjects usingBlock:(BOOL(^)(id obj))block;

/**
 * Reduces the receiver to a single value, using the given block.
 *
 * If the receiver is empty, `startingValue` is returned. Otherwise, the
 * algorithm proceeds as follows:
 *
 *  1. `startingValue` is passed into the block as the `left` value, and the
 *  first element of the receiver is passed into the block as the `right` value.
 *  2. The result of the previous invocation (`left`) and the next element of
 *  the receiver (`right`) is passed into `block`.
 *  3. Step 2 is repeated until all elements have been processed.
 *  4. The result of the last call to `block` is returned.
 *
 * @param startingValue The value to be combined with the first entry of the
 * receiver. If the receiver is empty, this is the value returned.
 * @param block A block that describes how to combine elements of the receiver.
 * If the receiver is empty, this block will never be invoked.
 *
 * @warning **Important:** Although this method is structured as a left fold,
 * the algorithm used for `block` must work irrespective of the order that the
 * set's elements are processed, as sets are unordered.
 */
- (id)mtl_foldWithValue:(id)startingValue usingBlock:(id (^)(id left, id right))block;

/**
 * Transforms each object in the receiver with the given predicate, returning
 * a new set built from the resulting objects.
 *
 * @param block A block with which to transform each element. The element from
 * the receiver is passed in as the `obj` argument. Returning `nil` from this
 * block will omit the entry from the resultant set.
 *
 * @warning Because sets only contain unique objects, the number of objects in
 * the result may be less than the number of objects in the receiver.
 */
- (id)mtl_mapUsingBlock:(id (^)(id obj))block;

/**
 * Transforms each object in the receiver with the given predicate, according to
 * the semantics of `opts`, returning a new set built from the resulting
 * objects.
 *
 * @param opts A mask of `NSEnumerationOptions` to apply when mapping.
 * @param block A block with which to transform each element. The element from
 * the receiver is passed in as the `obj` argument. Returning `nil` from this
 * block will omit the entry from the resultant set.
 *
 * @warning Because sets only contain unique objects, the number of objects in
 * the result may be less than the number of objects in the receiver.
 */
- (id)mtl_mapWithOptions:(NSEnumerationOptions)opts usingBlock:(id (^)(id obj))block;

/**
 * Returns an object in the receiver that passes the given test, or `nil` if no
 * such object exists.
 *
 * @param predicate The test to apply to each element in the receiver. This block
 * should return whether the object passed the test.
 */
- (id)mtl_objectPassingTest:(BOOL (^)(id obj, BOOL *stop))predicate;

/**
 * Returns an object in the receiver that passes the given test, or `nil` if no
 * such object exists.
 *
 * @param opts A mask of `NSEnumerationOptions` to apply when enumerating.
 * @param predicate The test to apply to each element in the receiver. This block
 * should return whether the object passed the test.
 */
- (id)mtl_objectWithOptions:(NSEnumerationOptions)opts passingTest:(BOOL (^)(id obj, BOOL *stop))predicate;

@end
